# Samsung prebuilts

Stock firmware blobs used by the build. They are extracted from the
corresponding Samsung firmware images with `scripts/download_fw.sh` +
`scripts/extract_fw.sh` (see `scripts/internal/update_prebuilt_blobs.sh`), and
the `.current` file in each directory records the firmware they came from.

The p3q (SM-G9980) port needs the directories below. Directories used by the
p3q/One UI 8.5 build are shipped in this repository so a clone can build
without downloading hundreds of gigabytes of firmware.

| directory | firmware (`.current`) | used for |
| --- | --- | --- |
| `p3qxxx` | SM-G9980 target firmware | target blobs, fs_config/file_context for the dynamic partitions |
| `a52qnsxx` | A525FXXSCFYF1/A525FOXMCFYF1/A525FXXSCFYF1 | shared A-series blobs referenced by UN1CA patches |
| `a73xqxx` | A736BXXSCGZE2/A736BOLMCGZE2/A736BXXSCGZE2 | 32-bit runtime / camera donor blobs |
| `dm1qksx` | S911NKSS8FZI1/S911NOKR8FZI1/S911NKSS8FZI1 | 32-bit runtime compatibility module (`zzz_runtime32_compat`) |
| `dm1qxxx` | S911BXXS9EZCI/S911BOXM9EZCI/S911BXXS9EZCI | donor system blobs |
| `dm3qxxx` | S918BXXS8EZA1/S918BOXM8EZA1/S918BXXU8EYI5 | donor system blobs |
| `pa1qxxx` | S931BXXU5BYI3/S931BOXM5BYI3/S931BXXU5BYI3 | donor system blobs |
| `pa3qxxx` | S931BXXU5BYI3/S931BOXM5BYI3/S931BXXU5BYI3 | donor system blobs |
| `q7qzcx` | placeholder (upstream) | shared quarantine blobs |
| `r9qxxx` | G990BXXSKIZF1/G990BOXMKIZF1/G990BXXSKIZE2 | donor blobs |
| `r11sxxx` | S711BXXSHGZG1/S711BOXMHGZG1/S711BXXSHGZG1 | secure-element / RIL donor blobs |
| `x1qksx` | placeholder (upstream) | 8250 donor blobs |
| `y2qksx` | placeholder (upstream) | 8250 donor blobs |
| `z3qksx` | placeholder (upstream) | 8250 donor blobs |

`extras/` holds the small misc blobs (NFC/test binaries) referenced by the
patch modules.

To refresh a directory against a newer firmware run:

```bash
source buildenv.sh p3q
bash scripts/download_fw.sh <DEVICE>
bash scripts/extract_fw.sh <DEVICE>
bash scripts/internal/update_prebuilt_blobs.sh <DEVICE>
```
