# Neural Style Transfer

💻 + 🎨 = 💙

## What is NST algorithm?
The algorithm transfers style from one input image (the style image) onto another input image (the content image) using CNN nets (usually VGG-16/19) and gives a composite, stylized image out which keeps the content from the content image but takes the style from the style image.

<p align="center">
<img src="data/examples/bridge/green_bridge_vg_la_cafe_o_lbfgs_i_content_h_500_m_vgg19_cw_100000.0_sw_30000.0_tv_1.0.jpg" width="570"/>
<img src="data/examples/bridge/content_style.jpg" width="260"/>
</p>


### Why yet another NST repo?
It's the **cleanest and most concise** NST repo that I know of + it's written in **PyTorch!** 💙
But here is the thing, this repo let you generate not only image but also videos !

### The flickering issue

A known issue on style transfer is what is so called the flickering effect. Indeed, each image is generated indepedently of each other. So when jumping from one frame to another, the transition is not very smooth and we get the impression that the frames jump.

An idea to solve this issue, is to add a temporal loss to the model, which depends on the preceeding image.

## How to create images
1. Open Anaconda Prompt and navigate into project directory `cd path_to_repo`
2. Run `conda env create` (while in project directory)
3. Run `activate pytorch-nst`

That's it! It should work out-of-the-box executing environment.yml file which deals with dependencies.

-----

PyTorch package will pull some version of CUDA with it, but it is highly recommended that you install system-wide CUDA beforehand, mostly because of GPU drivers. I also recommend using Miniconda installer as a way to get conda on your system.

Follow through points 1 and 2 of [this setup](https://github.com/Petlja/PSIML/blob/master/docs/MachineSetup.md) and use the most up-to-date versions of Miniconda (Python 3.7) and CUDA/cuDNN.
(I recommend CUDA 10.1 as it is compatible with PyTorch 1.4, which is used in this repo, and newest compatible cuDNN)

### Usage

1. Copy content images to the default content image directory: `/data/content-images/`
2. Copy style images to the default style image directory: `/data/style-images/`
3. Run `python neural_style_transfer.py --content_img_name <content-img-name> --style_img_name <style-img-name>`


## How to create videos

You can use the script `create_video.sh` (needs `ffmpeg` installed)

`-h, --help`         Print this help and exit

`-v, --verbose`      Print script debug info

`-c, --config`       Use the file config for args. Ignore other args
when used
`-u, --url`          The url of the video

`-q, --quality`      The quality of the video (144, 240, 360, 480,
720, ...)

`-b, --begin-from`   The beginning timecode (format mm:ss)

`-e, --end-at`       The ending timecode (format mm:ss)

`-H, --height`       The height of the outputed video

`-W, --width`        The width of the outputed video

`-f, --framerate`    The framerate of the video (24 for example)

`-s, --style`        The name of the style file (located in data/style-images)

`--gif`              Produce a gif instead of mp4

`--use-temporal`     Use the temporal loss to produce each picture


You can pass args by CLI or with a dedicated config file.

## Some example of our experiments

The main issue for us was the compute time. One image took 90s to generate on our GPU with 1000 iterations and LBFGS, so a 2s videos is 1.5 hour.

### Without temporal loss (1000 iteration)

<p align="center">
<img src="data/examples/gif/normal/video-candy-1000.gif" width="260"/>
<img src="data/examples/gif/normal/video-mosaic.gif" width="260"/>
</p>



## Acknoledgments

This repository is vastly based on https://github.com/gordicaleksa/pytorch-neural-style-transfer by Aleksa Gordić

We used two papers to implement this.

First this [one](https://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/Gatys_Image_Style_Transfer_CVPR_2016_paper.pdf), which describes the main process to apply style transfer on images.

Finally, we udes [this paper](https://openaccess.thecvf.com/content_cvpr_2017/papers/Huang_Real-Time_Neural_Style_CVPR_2017_paper.pdf) to implement th style transfer for videos with temporal smoothing.

## License
MIT

## Authors
Mathis Chalumeau, Arnaud Borquard, Ève Le Guillou, Thibault Ayanides