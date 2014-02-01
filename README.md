# ImageOptim Workflow for Alfred app

This is a wrapper Alfred workflow around the great [ImageOptim-CLI library](https://github.com/JamieMason/ImageOptim-CLI) from Jamie Mason. Mason's library uses three image optimization applications to automate optimization of JPEGs and PNGs. It uses the open source [ImageAlpha](https://github.com/pornel/ImageAlpha) and [ImageOptim](https://github.com/pornel/ImageOptim) apps, and the [JPEGmini](http://www.jpegmini.com/) app, which is not free, but highly recommended. Together they shrink images like a beast.

My own addition to this image processing is that if JPEGmini is unavailable, it uses ImageMagik's _mogrify_ to compress JPEGs to quality 75, if they're actually higher than 75. To do this, I'm also bundling ImageMagik's _mogrify_ and _identify_. A quality of 75 is usually pretty safe and it still has a way smaller size and usual JPEGs saved from Photoshop without optimization. That being said, JPEGmini does way better job and it's recommended.

## Requirements

* [ImageOptim](http://imageoptim.com/), installed in ```/Applications``` folder.
* [ImageAlpha](http://pngmini.com/), installed in ```/Applications``` folder.
* [JPEGmini](http://www.jpegmini.com/), _optional but recommended_, installed in ```/Applications``` folder.
* If using JPEGmini, you need to add Alfred 2 to the allowed apps in the accesibility list. Go to Preferences, Security and Privacy, Privacy tab, click the lock to allow changes, and drag the Alfred 2 app into the list.

## Usage

1. find or select one or more images or folders, show the file actions in Alfred, and select "Optimize Images".
  Note that any Alfred's way of selecting files work, such us:
  * select one or multiple files/folders in finder and press ```⌘ alt \```
  * browsing or finding files in Alfred, and triggering actions for the file
  * saving files in Alfred's file buffer, and then ```alt →``` to action buffered files.

  ![File actions](https://raw.github.com/ramiroaraujo/alfred-image-optim-workflow/master/screenshots/optimize.png)

2. You'll see a notification indicating the number of files to process. The work is done partially with AppleScript, so even if it's happening _in the background_, the apps are actually laoded and you can focus on them to check the status. Depending on the number and size of images, it could take a while.

  ![Process start](https://raw.github.com/ramiroaraujo/alfred-image-optim-workflow/master/screenshots/notification-start.png)

3. When the optimization is completed, you'll see another notification, indicating the original Kilobytes, the current Kilobytes, total savings and savings percent.

  ![Process finished](https://raw.github.com/ramiroaraujo/alfred-image-optim-workflow/master/screenshots/notification-feedback.png)

**The proccess _replaces_ the images with the optimized versions. Remember to save a copy or work with versioned files.**

## Caveats

You shouldn't run optimizations in parallel. Tecnically you could if the batch already jumped to the next app (from JPEGmini to ImageOptim for example), but it's looking for trouble. I'll consider adding a check in the future to prevent parallel process from happening, but I'm affraid this could add other complications, as in how to clear the _processing_ flag if optimization process is interrumpted earlier.


## Installation
For OS X 10.9 Mavericks, Download the [alfred-image-optim.alfredworkflow](https://github.com/ramiroaraujo/alfred-image-optim-workflow/raw/master/alfred-image-optim.alfredworkflow) and import to Alfred 2.

For Previous OS X Versions, Download the [alfred-image-optim.alfredworkflow](https://github.com/ramiroaraujo/alfred-image-optim-workflow/raw/pre-mavericks/alfred-image-optim.alfredworkflow) and import to Alfred 2.

## Changelog
* _2014-01-06_ - Released
* _2014-01-23_ - Added folder support, and correctly counting number of files inside folders