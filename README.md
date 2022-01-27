# BMS Rank Modifier
A PowerShell script aiming to modify BMS chart's judge window id (called and implemented as #RANK) automatically.
Supports only Windows with PowerShell (Possibly it will be Windows 7 or newer).

_I want to appreciate hnx8, who has a contribution a great library [hnx8/ReadJEnc](https://github.com/hnx8/ReadJEnc) for encoding detection._

![キャプチャ](https://user-images.githubusercontent.com/14097114/151207767-42b386cf-8535-465f-8d54-de9d6718dbda.PNG)

You also get a converting report.

![キャプチャ2](https://user-images.githubusercontent.com/14097114/151276755-87e22d75-6706-4ecd-8b4a-115f810c341d.PNG)


# How can I use it?
0. Download this repository as zip (or you can clone it if you have git on your computer).
1. Press Windows + R. Then you will be prompted with a "Run as" window.
2. A PowerShell instance appears, then type "Get-ExecutionPolicy" and press Enter.
3. If you see a result other from "Unrestricted", type "Set-ExecutionPolicy" and press Enter. Go to step 5 if not.
4. Type "Unrestricted" and press Enter. Any further prompt is just OK with "y".
5. Change a current directory with "cd" command to where you got in step 0.
6. Execute a command below:
```
.\ModifyBmsRank.ps1 {Directory path to where original BMS charts exist} {Directory path in order to save converted charts}
```
7. Be patient till the end of converting.
8. If you change the execution policy in step 2, do not forget to type "Set-ExecutionPolicy" and type "Stricted".
9. Done!

# CAUTION!
After modifying #RANK to your preference, I strongly recommend you NOT TO sign up any internet rankings because the ranking system can accept the modified charts as new ones when you send results to its server, meaning you are treated as the first player for the chart even if it is actually not. The script unfortunately cannot be your friend if you have a strong will to sign up internet rankings.

# More options available
.\ModifyBmsRank.ps1 {source} {destination} {copyOtherFile} {rankId} {preservesRankWhenAlreadyHarder}

## Source

Available value: String

Directory path to where original BMS charts exist.

## destination

Available value: String

Directory path in order to save converted charts.

## copyOtherFile

Available value: $true, $false

Default value: $false

When true, the script copies whole files in where an original chart exists. If false, the script only copies them to the destination directory and modifies their #RANK to what you want.

## rankId
Available value: Decimal

Default value: 3

You can specify a value of #RANK that you want apply to target charts.

## preservesRankWhenAlreadyHarder

Available value: $true, $false

Default value: $false

When true, the script skips modifying #RANK if an original chart has a definition of the narrower judge window with #RANK (Less the value is, narrower the window).

# Need difficulty tables?

In "CAUTION!" section, I have just explained why you should not join to internet rankings; The cause also affects to difficulty tables. Every #RANK-modified charts are treated as new ones, and almost every BMS player cannot identify that the charts are remain unchanged in essence, because they are mathematically quite different (See [Checksum - Wikipedia](https://en.wikipedia.org/wiki/Checksum)). I know this is terribly inconvenience for your play, and I made a new script for its solution. Go to ModifyBmsTableRank.ps1 and know what the script does (I will later explain it on another markdown textfile).

# License
hnx8/ReadJEnc
https://github.com/hnx8/ReadJEnc/blob/master/LICENSE

Copyright 2022 Yu Morino

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
