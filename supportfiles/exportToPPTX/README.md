## Overview

exportToPPTX allows user to create PowerPoint 2007+ (PPTX) files without using COM-objects automation (or PowerPoint application itself). Proper XML files are created and packaged into PPTX file that can be read and displayed by PowerPoint.

*Note about PowerPoint 2003 and older:* To open these PPTX files in older PowerPoint software you will need to get a free office compatibility pack from Microsoft: http://www.microsoft.com/en-us/download/details.aspx?id=3

## Usage

**Basic command syntax:**
```matlab
exportToPPTX('command',parameters,...)
```
    
**List of available commands:**

```matlab
exportToPPTX('new',...)
```

Creates new PowerPoint presentation. Actual PowerPoint files are not written until 'save' command is called. No required inputs. This command does not return any values. *Additional options:*
* `Dimensions` Two element vector specifying presentation's width and height in inches. Default size is 10 x 7.5 in.
* `Author` Specify presentation's author. Default is exportToPPTX.
* `Title` Specify presentation's title. Default is "Blank".
* `Subject` Specify presentation's subject line. Default is empty (blank).
* `Comments` Specify presentation's comments. Default is empty (blank).
* `BackgroundColor` Three element vector specifying document's background RGB value in the range from 0 to 1. By default background is white.

```matlab
exportToPPTX('open',filename)
```

Opens existing PowerPoint presentation. Requires file name of the PowerPoint file to be open. This command does not return any values.

```matlab
exportToPPTX('addslide',...)
```

Adds a slide to the presentation. No additional inputs required. Returns newly created slide number. *Additional options:*
* `Position` Specify position at which to insert new slide. The value must be between 1 and the total number of slides.
* `BackgroundColor` Three element vector specifying slide's background RGB value in the range from 0 to 1. By default background is white.
* `Master` Master layout ID or name. By default first master layout is used. When specifying master name, only as much of the name as ensures unique match has to be used. 
* `Layout` Slide template layout ID or name. By default first slide template layout is used. When specifying layout name, only as much of the name as ensures unique match has to be used. 

```matlab
exportToPPTX('addpicture',[figureHandle|axesHandle|imageFilename|CDATA],...)
```

Adds picture to the current slide. Requires figure or axes handle or image filename or CDATA to be supplied. Images supplied as handles or CDATA matrices are saved in PNG format. This command does not return any values. *Additional options:*
* `Scale` Controls how image is placed on the slide:
    * noscale - No scaling (place figure as is in the center of the slide or placeholder)
    * maxfixed - Max size while preserving aspect ratio (default)
    * max - Max size with no aspect ratio preservation
* `Position` Four element vector: x, y, width, height (in inches) or template placeholder ID or name. When exact position is specified Scale property is ignored. Coordinates x=0, y=0 are in the upper left corner of the slide. By default image is sized to the whole slide. When specifying placeholder name, only as much of the name as ensures unique match has to be used. 
* `LineWidth` Width of the picture's edge line, a single value (in points). Edge is not drawn by default. Unless either LineWidth or EdgeColor are specified. 
* `EdgeColor` Color of the picture's edge, a three element vector specifying RGB value. Edge is not drawn by default. Unless either LineWidth or EdgeColor are specified. 

```matlab
exportToPPTX('addtext',textboxText,...)
```

Adds textbox to the current slide. Requires text of the box to be added. This command does not return any values. *Additional options:*
* `Position` Four element vector: x, y, width, height (in inches) or template placeholder ID or name. Coordinates x=0, y=0 are in the upper left corner of the slide. By default textbox is sized to the whole slide. When specifying placeholder name, only as much of the name as ensures unique match has to be used. 
* `Color` Three element vector specifying RGB value in range from 0 to 1. Default text color is black.
* `BackgroundColor` Three element vector specifying RGB value in the range from 0 to 1. By default background is transparent.
* `FontSize` Specifies the font size to use for text. Default font size is 12.
* `FontWeight` Weight of text characters:
    * normal - use regular font (default)
    * bold - use bold font
* `FontAngle` Character slant:
    * normal - no character slant (default)
    * italic - use slanted font
* `Rotation` Determines the orientation of the textbox. Specify values of rotation in degrees (positive angles cause counterclockwise rotation).
* `HorizontalAlignment` Horizontal alignment of text:
    * left - left-aligned text (default)
    * center - centered text
    * right - right-aligned text
* `VerticalAlignment` Vertical alignment of text:
    * top - top-aligned text (default)
    * middle - align to the middle of the textbox
    * bottom - bottom-aligned text
* `LineWidth` Width of the textbox's edge line, a single value (in points). Edge is not drawn by default. Unless either LineWidth or EdgeColor are specified. 
* `EdgeColor` Color of the textbox's edge, a three element vector specifying RGB value. Edge is not drawn by default. Unless either LineWidth or EdgeColor are specified. 
* `OnClick` Add "jump to slide number" click action to the textbox. Slide number must be between 1 and maximum number of slides.

```matlab
exportToPPTX('addnote',noteText,...)
```

Adds notes information to the current slide. Requires text of the notes to be added. This command does not return any values. Note: repeat calls overwrite previous information. *Additional options:*
* `FontWeight` Weight of text characters:
    * normal - use regular font (default)
    * bold - use bold font
* `FontAngle` Character slant:
    * normal - no character slant (default)
    * italic - use slanted font

```matlab
exportToPPTX('addshape',xData,yData,...)
```

Add lines or closed shapes to the current slide. Requires X and Y data to be supplied. This command does not return any values. *Additional options:*
* `ClosedShape` Specifies whether the shape is automatically closed or not. Default value is false.
* `LineWidth` Width of the line, a single value (in points). Default line width is 1 point. Set LineWidth to zero have no edge drawn.
* `LineColor` Color of the drawn line, a three element vector specifying RGB value. Default color is black.
* `LineStyle` Style of the drawn line. The following styles are available:
    * - solid line (default)
    * : dotted line
    * -. dash-dot line
    * -- dashed line
* `BackgroundColor` Shape fill color, a three element vector specifying RGB value. By default shapes are drawn transparent.

```matlab
exportToPPTX('addtable',tableData,...)
```

Adds PowerPoint table to the current slide. Requires table content to be supplied in the form of a cell matrix. This command does not return any values. All of the `addtext` (textbox) additional options apply to the table as well.

```matlab
exportToPPTX('save',filename)
```

Saves current presentation. If PowerPoint was created with 'new' command, then filename to save to is required. If PowerPoint was opened, then by default it will write changes back to the same file. If another filename is provided, then changes will be written to the new file (effectively a 'Save As' operation). Returns full name of the presentation file written.

```matlab
exportToPPTX('close')
```

Cleans temporary files and closes current presentation. No additional inputs required. No outputs.

```matlab
exportToPPTX('saveandclose')
```

Shortcut to save and close at the same time. No additional inputs required. No outputs.

```matlab
exportToPPTX('query')
```

Returns current status either to the command window (if no output arguments) or to the output variable. If no presentation is currently open, returned value is null.

## Markdown

Any textual inputs (addtext, addnote) support basic markdown formatting: 
- Bulleted lists (lines start with "-")
- Numbered lists (lines start with "#")
- Bolded text (enclosed in "\*\*") Ex. this **word** is bolded
- Italicized text (enclosed in "\*") Ex. this *is* italics
- Underlined text (enclosed in "\_") Ex. this text is _underlined_

## Basic Example

Here is a very simple example

```matlab
% Start new presentation
exportToPPTX('new','Dimensions',[6 6]);

% Just an example image
load mandrill; figure('color','w'); image(X); colormap(map); axis off; axis image;

% Add slide, then add image to it, then add box
exportToPPTX('addslide');
exportToPPTX('addpicture',gcf,'Scale','maxfixed');
exportToPPTX('addtext','Mandrill','Position',[0 5 6 1],'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','bottom');

% Save and close
exportToPPTX('save','example.pptx');
exportToPPTX('close');
```

More elaborate examples are included in `examples_exportToPPTX.m` and `examples2_exportToPPTX.m` files.

## Notes about Templates

In order to use PowerPoint templates with exportToPPTX a basic knowledge of the structure of the template is required. You will need to know master layout name (especially if there are more than one master layout), slide layout names, and placeholder names on each layout slide. There are multiple ways of getting this information. 

The easiest way of getting template structure information is to open the presentation in PowerPoint and to look under Layout drop-down menu on the Home tab. Master name will be given at the top of the list. Layout names will be listed under each slide thumbnail. Placeholder names are not easy (if not impossible) to get to from PowerPoint itself. But typically they are named with obvious names such as Title, Content Placeholder, Text Placeholder, etc. 

Alternative way of getting template structure information is to open presentation template with exportToPPTX and run `query` which will list out all available master layouts, slide layouts, and placeholders on each slide layout. Here is an example with the included `Parallax.pptx` template:

```matlab
>> exportToPPTX open Parallax
>> exportToPPTX
	File: C:\Stefan\MatLab_Work\exportToPPTX\Parallax.pptx
	Dimensions: 13.33 x 7.50 in
	Slides: 0
	Master #1: Parallax
		Layout #1: Content with Caption (Title 1, Content Placeholder 2, Text Placeholder 3, Date Placeholder 4, Footer Placeholder 5, Slide Number Placeholder 6)
		Layout #2: Name Card (Title 1, Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #3: Section Header (Title 1, Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #4: Blank (Date Placeholder 1, Footer Placeholder 2, Slide Number Placeholder 3)
		Layout #5: Quote with Caption (TextBox 13, TextBox 14, Title 1, Text Placeholder 9, Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #6: Vertical Title and Text (Vertical Title 1, Vertical Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #7: Title and Content (Title 1, Content Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #8: Title and Vertical Text (Title 1, Vertical Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #9: Title Slide (Freeform 6, Freeform 7, Freeform 9, Freeform 10, Freeform 11, Freeform 12, Title 1, Subtitle 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #10: Title Only (Title 1, Date Placeholder 2, Footer Placeholder 3, Slide Number Placeholder 4)
		Layout #11: Title and Caption (Title 1, Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #12: Comparison (Title 1, Text Placeholder 2, Content Placeholder 3, Text Placeholder 4, Content Placeholder 5, Date Placeholder 6, Footer Placeholder 7, Slide Number Placeholder 8)
		Layout #13: True or False (Title 1, Text Placeholder 9, Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
		Layout #14: Panoramic Picture with Caption (Title 1, Picture Placeholder 2, Text Placeholder 3, Date Placeholder 4, Footer Placeholder 5, Slide Number Placeholder 6)
		Layout #15: Two Content (Title 1, Content Placeholder 2, Content Placeholder 3, Date Placeholder 4, Footer Placeholder 5, Slide Number Placeholder 6)
		Layout #16: Picture with Caption (Title 1, Picture Placeholder 2, Text Placeholder 3, Date Placeholder 4, Footer Placeholder 5, Slide Number Placeholder 6)
		Layout #17: Quote Name Card (TextBox 13, TextBox 14, Title 1, Text Placeholder 9, Text Placeholder 2, Date Placeholder 3, Footer Placeholder 4, Slide Number Placeholder 5)
```

Once you have all this structure information available it's easy to use templates with exportToPPTX. When creating new slide specify which slide layout you want to use. When adding text, images, or tables to the slide, instead of giving exact position and dimensions of the element, simply pass in the placeholder name. 

Here is a another simple example:

```matlab
% Open presentation template
exportToPPTX('open','Parallax.pptx');

% Add new slide with layout #9 (Title Slide)
exportToPPTX('addslide','Master',1,'Layout','Title Slide');	

% Add title text and subtitle text
exportToPPTX('addtext','Example Presentation','Position','Title'); 
exportToPPTX('addtext','Created with exportToPPTX','Position','Subtitle');

% Save as another presentation and close
exportToPPTX('save','example2');
exportToPPTX('close');
```

`Parallax.pptx`, included with this tool, is one of the default PowerPoint templates distributed with Microsoft Office 2013.
