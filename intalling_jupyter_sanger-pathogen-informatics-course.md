# I. installation of environment

## 1. installing Anaconda and Jupyter

The first piece of software you will need on your Mac is the software manager Anaconda. with that on your laptop, a lot of the bioinformatics software become available - not everything, but for the moment it should be covering what you need!  

You can download it there:
https://www.anaconda.com/distribution/

Make sure you download the Python 3.7 version of Anaconda.

Then, follow the installation instructions to have Anaconda installed on your laptop.


If you are in trouble, have a look at this step-by-step tutorial explaining how to install Anaconda - but only if you did not succeed at first:
https://towardsdatascience.com/how-to-successfully-install-anaconda-on-a-mac-and-actually-get-it-to-work-53ce18025f97

Once that is done, Jupyter should be available to you from the command line; specifically, you can find the `jupyter` excutable there:  
```
/anaconda3/bin/jupyter
```

Additionally, you need to install a kernel - don't worry about what it is, I'm not even sure myself, but it is required. So in the Teminal, type:
```
/anaconda3/bin/pip install bash_kernel
/anaconda3/bin/python -m bash_kernel.install
```

## 2. installing the training course environment

First, you need to create a folder where you will put all your software; it's not absolutely necessary but it's a good practice that will help you keep on top of your informatics business! Here is a suggestionm using the command line terminal:
```
mkdir -p ~/software/
```

Then, if you have the `git` command installed, run the following commands in your terminal:
```
cd ~/software/
git clone https://github.com/sanger-pathogens/pathogen-informatics-training.git
```
The first on will make you "change directory" to that new `software/` folder, and the second will download the code.

If `git` is not installed, you can instead go on the following web page:
https://github.com/sanger-pathogens/pathogen-informatics-training
and click on the green button *Clone or download* and then *Download ZIP*.
You should then uncompress the downloaded ZIP archive, and extract the folder `sanger-pathogens/` that it contains to place it into your folder of choice: `~/software/`, which should be accessible via your Finder file browser in you "home" folder.
NB: `~`is a shorthand for your "home" folder, i.e. `~` is equivalent to `/Users/NishaOrFatema`.

That should be it!

# II. running the tutorials

You can get started with typing (or more conveniently, copy-pasting!) this in your terminal:
```
/anaconda3/bin/jupyter notebook ~/software/pathogen-informatics-training/Notebooks/index.ipynb
```
This should open a new tab in your web browser, providing a graphic interface to navigate the courses. Now you can get started! I suggest you start by the first course, **Unix for Bioinformatics**.
