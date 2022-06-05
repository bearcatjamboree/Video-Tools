# Video Tools
Python code and shell scripts to help make video editing faster and easier

<img src="media/screenshot.png" width="900">

## Demo

[![IMAGE ALT TEXT HERE](media/Thumbnail.png)](https://www.youtube.com/watch?v=Ep2jBjvIZwI)

If you find these tools useful then consider watching my other content and subscribing to my channel.

## Features

1. Audio-level and facial recognition based jump-cutting
2. Audio-level based jump-cutting
3. Audio-level and template match based jump-cutting
4. Burn subtitles from SRT file
5. Batch convert video format
6. Batch generate speech from text
7. Batch merge video and audio
8. Burn subtitles from SRT
9. Change video aspect ratio
10. Change volume amount
11. Compress audio file
12. Convert video format
13. Create animated GIF
14. Create mobile crossclip
15. Create pencil sketch video
16. Create vintage video
17. Crop video
18. Cut video start to duration
19. Cut video start to endTime
20. Download YouTube video
21. Extract audio from video
22. Extract images from video
23. Facial recognition base jump-cutting
24. Flip video horizontally
25. Flip video vertically
26. Generate game highlights
27. Generate speech from text
28. Generate video subtitles
29. Jump-cutting based on template matching
30. Merge video and audio
31. Mirror video horizontally
32. Mirror video vertically
33. Plot sound frames
34. Plot video frames
35. Remove audio from video
36. Remove background music
37. Remove video background
38. Remove vocals
39. Resize video
40. Reverse video
41. Rotate video clockwise
42. Rotate video counterclockwise
43. Translate YouTube description
44. Translate YouTube playlist
45. Translate YouTube transcript
46. Translate YouTube cideo
47. Zoom-pan cut video
 
## Operating Systems

- MacOS
- Linus
- Windows 8+ with Cygwin or Bash for Windows
- Windows 10/11 with WSL (Windows Subsystem for Linux) 

To install WSL see the link below:
https://docs.microsoft.com/en-us/windows/wsl/install

List of terminal emulated:
https://www.jetbrains.com/help/pycharm/terminal-emulator.html#configure-the-terminal-emulator

However, PowerShell (powershell) & Command Prompt (cmd.exe) do not support the scripts I this project.

## Pre-requisites

1. Python 3+ - Python is an interpreted, object-oriented, high-level programming language with dynamic semantics.

2. Imutils - A series of convenience functions to make basic image processing functions such as translation, rotation, resizing, skeletonization, displaying Matplotlib images, sorting contours, detecting edges, and much more easier with OpenCV and both Python 2.7 and Python 3.

3. Numpy - the fundamental package for array computing with Python.

4. OpenCV - OpenCV (Open Source Computer Vision Library) is an open source computer vision and machine learning software library.

5. SpeechRecognition - Library for performing speech recognition, with support for several engines and APIs, online and offline.

    To test for setup errors, simple type the following command and talk into your microphone to see if it translates your voice to text:

    ```python -m speech_recognition```

6. Spleeter

## Installation

1. Install Homebrew

    ```/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"```

2. Install Python

    ```brew install python```

3. PyCharm CE (Community Edition) - Free

    PyCharm can be downloaded here: https://www.jetbrains.com/pycharm/download

4. Setup Project in pyCharm

    When setting up the new project, be sure to create a new virtual environment with the Homebrew Python installation as the base interpreter, and check both "Inherit global site-packages, and "Make available to all projects."

5. Install Video-Tools by performing the following steps:

    A. Select the pyCharm project directory

    B. Issue the following command from the shell inside the project directory in Step A:

   ```git clone https://github.com/bearcatjamboree/Video-Tools.git```

    C. Type the following command to install pre-requisite python modules:

   ```pip install -r requirements.txt```
        
    D. To setup Spleeter on Non-M1 systems type the following command from the shell:
    
   ```pip install spleeter```

    On Mac M1 system follow these steps:

    https://github.com/jeffheaton/t81_558_deep_learning/blob/master/install/tensorflow-install-mac-metal-jul-2021.ipynb
    
    NOTE: the Run->Edit Configurations menu can now be used to create references to the shell scripts to make them easily accessible through the pyCharm client.
    
6. Cascade Trainer GUI (Version 3.3.1 or better):

    If you want to train your own Haar Cascade Classifiers then this GUI can help make training and testing much easier:
    https://drive.google.com/drive/folders/1kZDzGx_RKu3qH_QONSxksR7gfZReevMg

    Install the GUI with Wineskin if on Mac/Linux.  Wineskin can be downloaded and installed through HomeBrew using the following command:

    ```brew install --no-quarantine gcenx/wine/unofficial-wineskin```

## Known Issues

For M1 installations, to use the RemoveVocals.sh or RemoveBackgroundMusic.sh you must enter:

   ```conda activate spleeter```

Note, this is only if you called the separate environment "spleeter."

If you attempt to use PyTTSx3 while the spleeter environment is active then you will have issues with translating text to speech through Mac OS NSS.

If you found these tools helpful then please consider subscribing to one of my YouTube channels:

English:
https://www.youtube.com/c/Bearcatjamboree?sub_confirmation=1

Spanish:
https://www.youtube.com/channel/UCnRVM0LLt-XgBeO3U-b1qbA?sub_confirmation=1

Chinese:
https://www.youtube.com/channel/UCnXDKHYWebD065Ed-FlvhwQ?sub_confirmation=1

Hindi:
https://www.youtube.com/channel/UCE1zO3HLk8DIc2zTsl7eH5Q?sub_confirmation=1

Arabic:
https://www.youtube.com/channel/UCkESzVVlDDB69-XJOWlDn8g?sub_confirmation=1

Indonesian:
https://www.youtube.com/channel/UCy5k3dtLtjn8FVmo8tNWeBQ?sub_confirmation=1
