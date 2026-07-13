<!-- LOGO -->
<p align="center">
  <img width="128" height="128" alt="nordplayer_icon" src="https://github.com/user-attachments/assets/761d4002-0f94-46fe-a323-fdd65fe4091c" />
<h2 align="center">
  Nordplayer
</h2>
<p align="center">
  A desktop music player built with customization and theming in mind.
  <br>
  <br>
  <a href="https://github.com/jpangestu/nordplayer/releases/latest">
    <!-- GitHub Downloads (all assets, all releases -->
    <img alt="Downloads" src="https://img.shields.io/github/downloads/jpangestu/nordplayer/total?style=flat&label=Downloads">
  </a>
  <a href="#screenshot">
    <img alt="Static Badge" src="https://img.shields.io/badge/Screenshot-5e81ac?style=flat">
  </a>
  <a href="https://discord.gg/RH5j8H2Y">
    <img alt="Static Badge" src="https://img.shields.io/badge/Discord-5e81ac?style=flat&logo=discord&logoColor=white">
  </a>
</p>

## Installation

**Windows**

Download the setup from the [Releases](https://github.com/jpangestu/nordplayer/releases/latest) page and run it.


**Arch-based Linux**

```bash
yay -S nordplayer-bin
# or
paru -S nordplayer-bin
```

**Other Linux Distributions**

Grab the pre-compiled `.tar.gz` from the [Releases](https://github.com/jpangestu/nordplayer/releases/latest) page, extract it, and run the `nordplayer` executable inside. If it fail to run, it's probably because of missing dependency. So run the `nordplayer` executable from terminal to see the missing dependencies and install those.

**Build from source**

Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed along with desktop development requirements for your platform.

1. Clone the repository:
```bash
git clone https://github.com/jpangestu/nordplayer.git
cd nordplayer
```
2. Get dependencies:
```bash
flutter pub get
```
3. Build the application:
```bash
# For Linux
flutter build linux

# For Windows
flutter build windows
```
The compiled executable will be located in `build/linux/x64/release/bundle/` for Linux or `build/windows/x64/runner/Release/` for Windows.

## But Why?
Of all the music players I've tried (I tried a lot of them, btw), I still haven't found one that's of my preference. The closest I could get was MusicBee, but that only runs on Windows.

A lot of the other options, especially the ones that also run on linux, still have what I call "old UIs" --look at Rhythmbox, Strawberry, Elisa. While most of them are performant because they use C/C++, I just don't like it --not saying they're bad, it's just not my preference, I want something more modern.

And since I'm something of a programmer myself, why can't I just build one? Or try, at least. So, here we are.

## Current App State
This app is still very early in the development stage. Expect some bugs and unimplemented features.

## Screenshot
<img width="1920" height="1030" alt="preview1" src="https://github.com/user-attachments/assets/a35114f6-3ac3-4904-bc3b-5ae3611c9b06" />
<img width="1920" height="1030" alt="preview2" src="https://github.com/user-attachments/assets/5331f78a-8abb-47b5-9662-b1f19543f8cb" />
<img width="1920" height="1030" alt="preview3" src="https://github.com/user-attachments/assets/e9b5030b-179b-4ef0-acbc-cbf9d39bffbd" />
<img width="1920" height="1030" alt="preview4" src="https://github.com/user-attachments/assets/17e363f6-22ca-4b9a-8b97-edd4035ffc29" />
<img width="1920" height="1030" alt="preview5" src="https://github.com/user-attachments/assets/6b581c18-b5ca-4e47-85d9-c99c8f82f75a" />
<img width="1920" height="1030" alt="preview6" src="https://github.com/user-attachments/assets/a4b70f07-e562-4066-8b9c-7df037746745" />
<video src="https://github.com/user-attachments/assets/5f1836f0-81bc-4463-abe5-96bbc47126eb" controls="controls" style="max-width: 100%;">
</video>
