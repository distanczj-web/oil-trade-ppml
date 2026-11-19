"""Restore the frozen replication files from the checked archive parts."""
from hashlib import sha256
from pathlib import Path
from zipfile import ZipFile
import argparse
import json
import os
import tempfile

ROOT=Path(__file__).resolve().parent


def digest(path):
    result=sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda:stream.read(1024*1024),b''):
            result.update(chunk)
    return result.hexdigest()


def destination(relative):
    path=(ROOT/relative).resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError('Archive path leaves the replication directory.')
    return path


def verify_replication_files():
    original=json.loads((ROOT/'SHA256.json').read_text('utf8'))
    failed=[]
    for name,expected in original.items():
        path=destination(name)
        if not path.is_file() or digest(path)!=expected:
            failed.append(name)
    if failed:
        raise RuntimeError('Replication file verification failed\n'+'\n'.join(failed))
    print(f'All {len(original)} original replication files match their frozen checksums.')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-only',action='store_true')
    parser.add_argument('--force',action='store_true',help='Replace existing files that differ from the frozen inputs.')
    args=parser.parse_args()
    plan=json.loads((ROOT/'data_archive/manifest.json').read_text('utf8'))
    for part in plan['parts']:
        path=destination(part['path'])
        if not path.is_file() or path.stat().st_size!=part['size'] or digest(path)!=part['sha256']:
            raise RuntimeError('Archive part verification failed: '+part['path'])
    if args.verify_only:
        verify_replication_files()
        return
    pending=[]
    for entry in plan['files']:
        path=destination(entry['path'])
        if path.exists():
            if digest(path)==entry['sha256']:
                continue
            if not args.force:
                raise RuntimeError('An existing file differs from the frozen copy: '+entry['path']+
                                   '\nUse --force to restore the frozen input.')
        pending.append(entry)
    if not pending:
        verify_replication_files()
        return
    with tempfile.TemporaryFile() as stream:
        full_digest=sha256()
        for part in plan['parts']:
            with destination(part['path']).open('rb') as source:
                for chunk in iter(lambda:source.read(1024*1024),b''):
                    stream.write(chunk)
                    full_digest.update(chunk)
        if stream.tell()!=plan['archive_bytes'] or full_digest.hexdigest()!=plan['archive_sha256']:
            raise RuntimeError('The combined data archive does not match its checksum.')
        stream.seek(0)
        with ZipFile(stream) as archive:
            if set(archive.namelist())!={entry['path'] for entry in plan['files']}:
                raise RuntimeError('Archive membership does not match the data manifest.')
            for index,entry in enumerate(pending,1):
                target=destination(entry['path'])
                target.parent.mkdir(parents=True,exist_ok=True)
                temporary=target.with_name(target.name+'.restoretmp')
                try:
                    value=sha256()
                    count=0
                    with archive.open(entry['path']) as source,temporary.open('wb') as output:
                        for chunk in iter(lambda:source.read(1024*1024),b''):
                            output.write(chunk)
                            value.update(chunk)
                            count+=len(chunk)
                    if count!=entry['size'] or value.hexdigest()!=entry['sha256']:
                        raise RuntimeError('Restored file verification failed: '+entry['path'])
                    os.replace(temporary,target)
                finally:
                    if temporary.exists():
                        temporary.unlink()
                print(f'Restored {index}/{len(pending)} {entry["path"]}',flush=True)
    verify_replication_files()


if __name__=='__main__':
    main()
