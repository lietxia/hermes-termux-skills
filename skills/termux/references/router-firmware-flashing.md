# Third-Party Firmware Flashing (OpenWrt / Padavan / Breed)

## Decide support before anything else

1. **OpenWrt Wiki Table of Hardware** (`openwrt.org/toh`) — search the exact
   model. A techdata page means official support, and the install / sysupgrade
   image URLs are listed on it. No page → self-compile or skip.
2. **Board string, not marketing name.** Flashing files are keyed to the
   device-tree / board string. The JDCloud "无线宝 1代 加速版 64G" shows model
   `JDC-1P` in its app but the board is `jdcloud_re-sp-01b` (`RE-SP-01B`). A
   file for one board bricks another — confirm the board string from
   SSH/telnet or a teardown before trusting any download.
3. **Firmware version gates the method.** The exploits that allow flashing
   without opening the case (SSH backdoors, recovery-mode gaps) are patched in
   newer firmware. Same model, old firmware → flash via the web recovery page;
   same model, current firmware → open the case and use a programmer. Search
   the community thread for the exact version: "works on rXXXX, fails on
   rYYYY" is the pattern.

## JDCloud 无线宝 1代 (RE-SP-01B)

| Item | Value |
|------|-------|
| SoC | MediaTek MT7621AT (ramips / mt7621, mipsel_24kc) |
| RAM / Flash | 512 MB / 32 MB SPI + 64 GB eMMC |
| Wi-Fi | MT7603EN (2.4G) + MT7615N (5G) |
| OpenWrt | official support since 25.12.0 |
| Image | `openwrt-<ver>-ramips-mt7621-jdcloud_re-sp-01b-squashfs-sysupgrade.bin` |

Old firmware (JDCOS ~r6636): recovery-mode flash of an SSH-enabled vendor
build → `mtd write /breed-mt7621-jd-cloud-1.bin Bootloader` → Breed → OpenWrt.
Current firmware (r6645+): exploit patched → disassembly + programmer required.

## Programmer flashing (when the case-free exploit is patched)

- CH341A programmer, **standard** revision — clones/modded ones fail to read
  large chips.
- **SOP16** (16-pin) clip; the 8-pin clip most kits ship will not fit.
- **Windows 10 only** — Win11 does not bind the CH341A driver.
- Read and save the original flash first; it is the only unbrick path.
- Flash Breed, then install OpenWrt/Padavan from Breed's web UI.

## Pitfalls

- Confirm the board string before downloading anything — the app model name
  is not the board string.
- **Back up EEPROM / ART** (radio calibration) before writing; losing it
  degrades or kills Wi-Fi.
- Never flash a file built for a different board string.
- Sources: 恩山无线论坛 (right.com.cn), OpenWrt Wiki ToH, dt27.cn,
  lishuma.com.
