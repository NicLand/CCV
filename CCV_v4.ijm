//CCV v4 for Juliette Villagomez by Nicolas Landrein - Spacvir 2026

//Parameters: modify, but please leave the var at the beginning of the line and the ; at the end of the line!!!

var nerdMode = true;

var countIntoNucleus = true; //Set to true if dot count is needed for the experiment/

//======= START nerdmode = true :  please fill the var below ========
var marker1_def = "p53";
var marker2_def = "gH2AX";
var marker3_def = "pVII";
var marker4_def = "Dapi";

var cellsChannel = marker2_def;// Channel where you want to draw the cells
var virusChannel = marker3_def;// Virus Channel : fill up with the variable below as marker*_def
var dapiChannel = marker4_def;// DAPI Channel

//======= END nerdmode = true =======

//======= START nerdMode = false =======

var marker1Channel=1; //The channel number for marker 1
var marker2Channel=2; //The channel number for marker 2. Do not modify in case you only have 3 channels
var marker3Channel=3; //The channel number for virus
var DAPIChannel=4; //The channel number for DAPI


//***** Marker Detection *****
var thr=10000; //Minimum threshold for markers 
var minSize=10; //Minimum surface for markers , in pixels
var maxSize=1000; //Maximum surface for markers, in pixels

//***** Min/max sizes of overlap to be considered as colocalisation *****
var minColocSize=10; //Minimum overlap between two/three markers to be considered as colocalisation, in pixels
var maxColocSize=1000; //Maximum overlap between two/three markers to be considered as colocalisation, in pixels


var interactiveModeON=true; //Set to true for interactive mode, to false for non interactive mode

//======= END nerdmode = false =======

//======= FORM TO NAME IMAGES =======
if(nerdMode == true){
	
	marker1_name = marker1_def;
	marker2_name = marker2_def;
	marker3_name = marker3_def;
	marker4_name = marker4_def;

	channelsNames = newArray(marker1_name,marker2_name,marker3_name, marker4_name);
	
}

else{
	
	Dialog.create("Image name");
	Dialog.addMessage("Please choose your markers");
	Dialog.addString("Marker1 :",marker1_def);
	Dialog.addString("Marker2 :",marker2_def);
	Dialog.addString("Marker3 :",marker3_def);
	Dialog.addString("Marker4 :",marker4_def);
	Dialog.show();
	
		marker1_name = Dialog.getString();
		marker2_name = Dialog.getString();
		marker3_name = Dialog.getString();
		marker4_name = Dialog.getString();
		channelsNames=newArray(marker1_name,marker2_name);

	Dialog.create("Cell channel");
	Dialog.addMessage("On which channel do you want to define cells");
	Dialog.addChoice("Channel : ", channelsNames);
	Dialog.show();
	cellsChannel = Dialog.getChoice();

	Dialog.create("Virus channel");
	Dialog.addMessage("On which channel are the spot to count");
	Dialog.addChoice("Channel : ", channelsNames);
	Dialog.show();
	virusChannel = Dialog.getChoice();

	Dialog.create("Dapi channel");
	Dialog.addMessage("On which channel are the Nuclei");
	Dialog.addChoice("Channel : ", channelsNames);
	Dialog.show();
	dapiChannel = Dialog.getChoice();
	
}

//================================================
//--------------DO NOT MODIFY ANYTHING BELOW THIS LINE-------------------

var channelsNumbers=newArray(marker1Channel,marker2Channel, marker3Channel, DAPIChannel);

var ori=getTitle();
var channels=4;

run("Options...", "iterations=1 count=1 black");

process();

run("Options...", "iterations=1 count=1");

//------------------------------------------------------------------------
function process(){
	getDimensions(width, height, channels, slices, frames);
	
	if(slices>1){
		
		run("Z Project...", "projection=[Max Intensity]");
	}
	rename("Max_"+ori);
	close(ori);
	
	setImages("Max_"+ori);
	selectCells();
	
	if(countIntoNucleus == true){
	selectNuclei();
	}
	else{
		}
	
	for (i = 0; i < channels-1; i++){
		getMarkerMask(channelsNames[i], thr, minSize, maxSize);
	}

	getCombinedMasks();

	analyseAllCells();
	
	getControlImage();
	
	run("Tile");
	selectWindow("Coloc");
}

//------------------------------------------------------------------------
function setImages(img){
	selectWindow(img);
	
	for(i=0; i<channels; i++){
		selectWindow(img);
		run("Duplicate...", "title="+channelsNames[i]+" duplicate channels="+channelsNumbers[i]);
	
	}
}

//------------------------------------------------------------------------
function selectCells(){
	selectWindow(cellsChannel);
	roiManager("Reset");
	roiManager("Show All");

	setTool("freehand");
	run("Brightness/Contrast...");
	waitForUser("1-Adapt contrast/brightness\n2-Delineate cells using the ROI tool\n3-Add them to the ROI Manager by pressing 't'\n4-Once all cells have been added, click on Ok");

	for(i=0; i<roiManager("Count"); i++){
		roiManager("Select", i);
		roiManager("Rename", "Cell"+(i+1));
	}

	roiManager("Show All with labels");
	roiManager("UseNames", "true");
	run("Select None");
}

//------------------------------------------------------------------------
function selectNuclei(){
	
	selectWindow(dapiChannel);
	
	setOption("BlackBackground", true);

	run("Threshold...");
		setAutoThreshold("Triangle dark no-reset");
		waitForUser("1-Modify the threshold to highlight the nuclei area\n2-PRESS APPLY !!!\n3-Once done, click Ok");
	
	nbTour = roiManager("count");

	for(i=0;i<nbTour; i++){
		roiManager("select", i);
		roiName = Roi.getName();
		run("Analyze Particles...", "size=10000-10000000 pixel add");
	}

	nbTour2 = roiManager("count");
	
	for(j=0; j<nbTour2; j++){
		roiManager("select", j);
		roiName = Roi.getName();
		if(roiName.contains("Cell")){
	}
	else{
		print(roiName);
		roiManager("Rename", "Nuclei"+(j+1-nbTour));
	}
	roiManager("Show All with labels");
	roiManager("UseNames", "true");
}
}

//------------------------------------------------------------------------
function getMarkerMask(marker, thr, minSize, maxSize){
	selectWindow(marker);
	run("Grays");
	
	getStatistics(area, mean, min, max, std, histogram);
	run("Select None");

	roiManager("Deselect");
	roiManager("Combine");

	if(interactiveModeON){
		run("Subtract Background...", "rolling=50");
		run("Threshold...");
		setAutoThreshold("Triangle dark no-reset");
		waitForUser("1-Modify the threshold to highlight the "+marker+" area\n2-PRESS APPLY !!!\n3-Once done, click Ok");
		roiManager("Deselect");
		roiManager("Combine");
		setBackgroundColor(0, 0, 0);
		run("Clear Outside");
	}else{
		setThreshold(thr, max);
	}
	
	run("Analyze Particles...", "size="+minSize+"-"+maxSize+" pixel show=Masks");
	rename(marker+"_Detections");
	run("Grays");
}

//------------------------------------------------------------------------
function getCombinedMasks(){
	//All doubles
	for(i=0; i<channels-1; i++){
		for(j=i+1; j<channels-1; j++){
			imageCalculator("AND create", channelsNames[i]+"_Detections", channelsNames[j]+"_Detections");
			rename("Double-positives_"+channelsNames[i]+"-"+channelsNames[j]);
		}
	}

	//Triple, if applicable
	if(channels>3){
		imageCalculator("AND create", "Double-positives_"+channelsNames[0]+"-"+channelsNames[1], channelsNames[2]+"_Detections");
		rename("Triple-positives_"+channelsNames[0]+"-"+channelsNames[1]+"-"+channelsNames[2]);
	}
}

//------------------------------------------------------------------------
function analyseAllCells(){
	findOrCreateTable("Coloc");
	for(i=0; i<roiManager("Count"); i++){
		roiManager("Select", i);
		ROIname = Roi.getName();
		selectWindow("Coloc");
		Table.set("Image", Table.size, ori);
		Table.set("ROIs", Table.size-1, ROIname);
		Table.update;
		getAnalysis(i);
	}
}

//------------------------------------------------------------------------
function getAnalysis(roi){
	//Single analysis
	findOrCreateTable("Coloc");
	row=Table.size-1;
	for(i=0; i<channels-1; i++){
		performAnalysis(""+channelsNames[i]+"_Detections", roi, row);
	}
	
	//All doubles
	for(i=0; i<channels-1; i++){
		for(j=i+1; j<channels-1; j++){
		//print("Double-positives_"+channelsNames[i]+"-"+channelsNames[j]);
			performAnalysis("Double-positives_"+channelsNames[i]+"-"+channelsNames[j], roi, row);
		}
	}

	//Triple, if applicable
	if(channels>3) performAnalysis("Triple-positives_"+channelsNames[0]+"-"+channelsNames[1]+"-"+channelsNames[2], roi, row);
}

//------------------------------------------------------------------------
function performAnalysis(image, roi, row){
	selectWindow(image);
	roiManager("Select", roi);
	run("Clear Results"); //Requiered for proper numbering of the objects
	run("Analyze Particles...", "size="+minColocSize+"-"+maxColocSize+" pixel show=[Count Masks]");
	getStatistics(area, mean, min, max, std, histogram);
	close();
	selectWindow("Coloc");
	Table.set(image, row, max);
	Table.update;
}

//------------------------------------------------------------------------
function getControlImage(){
	arg="";
	for(i=0; i<channels-1; i++){
		arg+="c"+(i+1)+"="+channelsNames[i]+"_Detections ";
		close(channelsNames[i]);
	}
	run("Merge Channels...", arg+"create");
	rename("Control-Image_"+ori);
	roiManager("Show All with labels");
}


//-------------------------------------------------------------------------------------------------------
function findOrCreateTable(name){
	winTitle=getList("window.titles");
	found=false;
	for(i=0; i<winTitle.length; i++){
		if(winTitle[i]==name){
			found=true;
		}
	}
	
	if(!found){
		Table.create(name);
	}
}