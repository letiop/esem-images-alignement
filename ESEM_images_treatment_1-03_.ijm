start = getTime(); 

//*****************function to get time and temperature from Tiff File

  function GettandT(Tmeasured) {
     
tagnum=34682;

//Gets the path+name of the active image
path = getDirectory("image");
if (path=="") exit ("path not available");
name = getInfo("image.subtitle"); //filename if image alone, subtitle if stack
if (name=="") exit ("name not available");
i0 = indexOf(name, "("); //test to try to read out information from stack: failed
i1 = indexOf(name, ");");
name=substring(name,i0+1,i1)+".tif";
path = path +"//"+name;

//Gets the tag, and parses it to get the date and time
tag = call("TIFF_Tags.getTag", path, tagnum);
i0 = indexOf(tag, "Date=");
if (i0==-1) exit ("Date information not found");
i1 = indexOf(tag, "=", i0);
i2 = indexOf(tag, "Time=", i1);
if (i1==-1 || i2==-1 || i2 <= i1+4)
   exit ("Parsing error! Maybe the file structure changed?");
Date = substring(tag,i1+1,i2-2);//

i0 = indexOf(tag, "Time=");
if (i0==-1) exit ("Time information not found");
i1 = indexOf(tag, "=", i0);
i2 = indexOf(tag, "[SYSTEM]", i1);
if (i1==-1 || i2==-1 || i2 <= i1+4)
   exit ("Parsing error! Maybe the file structure changed?");
Time = substring(tag,i1+1,i2-4);//

if(substring(Time,1,2)==":") a=0; //check if hours is one or two digits
else a=1;

if(substring(Time,8+a,10+a)=="PM"&&substring(Time,0,1+a)!="12") MomentofDay=12; //MomentofDay is 12 if afternoon to add 12 hours
else if(substring(Time,8+a,10+a)=="AM"&&substring(Time,0,1+a)=="12") MomentofDay=-12; //12 hours less for midnight
else MomentofDay=0; //no addition of hours in the morning
Hours=parseInt(substring(Time,0,1+a))+MomentofDay;
Minutes=parseInt(substring(Time,2+a,4+a));
Seconds=parseInt(substring(Time,5+a,8+a));
if(substring(Date,1,2)=="/") b=0; //check if month is one or two digits
else b=1;
if(substring(Date,3+b,4+b)=="/") c=0; //check if day is one or two digits
else c=1;
Day=parseInt(substring(Date,2+b,3+b+c));
Month=parseInt(substring(Date,0,1+b));
Year= parseInt(substring(Date,4+b+c,8+b+c));


//Gets the tag, and parses it to get the temperature
if(Tmeasured){
	i0 = indexOf(tag, "Temperature=");
	if (i0==-1) exit ("Temperature information not found");
	i1 = indexOf(tag, "=", i0);
	i2 = indexOf(tag, "[Detectors]", i1);
	if (i1==-1 || i2==-1 || i2 <= i1+4)
	   exit ("Parsing error! Maybe the file structure changed?");
	if(i2-11<i1+1){
		Temperature=-100;}
	else {
	Temperature =parseInt(substring(tag,i1+1,i2-11))-273;}}
  
else Temperature=-400;

	tag = call("TIFF_Tags.getTag", path, tagnum);
	i0 = indexOf(tag, "PixelHeight=");
	
	if (i0==-1) exit ("Scale information not found");
	i1 = indexOf(tag, "=", i0);
	i2 = indexOf(tag, "PixelWidth", i1);
	if (i1==-1 || i2==-1 || i2 <= i1+4)
	   exit ("Parsing error! Maybe the file structure changed?");
	
	
	scale = parseFloat(substring(tag,i1+1,i2-7));
	Power=parseInt(substring(tag,i2-5,i2-2));
	
R= newArray(Year,Month, Day, Hours, Minutes, Seconds,Temperature,scale,Power,Date,Time);

 return R;
   }


// ******************************************** dialog boxes to define tasks and get information from user********************************************
autoT=0;
boarder=0;
directory="null";
setBackgroundColor(0, 0, 0);
parameterstack=8;
parameteralignment=8;

  Dialog.create("ESEM movie maker");
  Dialog.addMessage("This macro help in making movie from images recorded in ESEM.");
  Dialog.addMessage("Which processing do you want to apply ? (For each selected action, more information will be asked)");
  Dialog.addCheckbox("Open images stack (import all images from one folder)", false);
  //Dialog.addCheckbox("Duplicate stack", true);  
  Dialog.addCheckbox("Brightness/contrast adjust",false);
  Dialog.addCheckbox("Align", false);
  Dialog.addCheckbox("Crop",false);
  Dialog.addCheckbox("Make databar", true);
  Dialog.addCheckbox("Display temperature statitstics", false);
  Dialog.show();
  process_open= Dialog.getCheckbox();
  process_contrast=Dialog.getCheckbox();
  process_align= Dialog.getCheckbox();
  process_crop= Dialog.getCheckbox();
  process_databar= Dialog.getCheckbox();
  process_tempstat= Dialog.getCheckbox();
  
  process_duplicate= process_align;


Dialog.create("ESEM movie maker options");



//Dialog.addString("Directory of the original images:"," ");

//Dialog.addString("Directory:","C:/Users/Stephane Poitel/Desktop/anode2");
Dialog.addString("Directory:","C:/Users/Stephane Poitel/Desktop/temporary file2");
Dialog.addMessage("Only the images for the movie should be located \n in the selected folder.");
	
if(process_align==true) Dialog.addNumber("Boarder to be added before alignement:", 200); //the larger the more chance to avoid loss information in case of drift but the longer to align
if(process_crop==true)Dialog.addChoice("Cropping precision after alignement",  newArray("no black boarder visible","minmimum black boarder (extreme value removed)", "minimum black boarder", "no crop", "personnalised")); //"two stacks:with and without boarder"
if(process_tempstat==true||process_databar==true)  {
	Dialog.addChoice("Initial time:", newArray("personnalised", "from first image of stack"));
	Dialog.addCheckbox("Temperature was measured in-situ:", true);
	Dialog.addCheckbox("Use of several gas:", false);}
 
if(process_databar==true){
  	Dialog.addChoice("Display the time in the databar in:", newArray("sec","min", "h")); 
  	Dialog.addChoice("Add a time bar reader:", newArray("no", "yes"));
  	if (process_crop==false)Dialog.addNumber("Length of databar:", 200);   	
  	}
Dialog.show();

directory = Dialog.getString();
if(process_align==true) boarder = Dialog.getNumber();
if(process_crop==true) crop_choice = Dialog.getChoice();
if(process_tempstat==true||process_databar==true) {
	time_choice = Dialog.getChoice();
	Temp_meas= Dialog.getCheckbox();
	gas=Dialog.getCheckbox();
}

if(process_databar==true ) {
	timedisplay_choice = Dialog.getChoice();
	timebar_choice = Dialog.getChoice();
	if (process_crop==false)databar_length = Dialog.getNumber();
}

if(process_crop==true){
	
	if(crop_choice=="personnalised"){
  		Dialog.create("ESEM movie maker, personnalised cropping");
  		Dialog.addNumber("Percentage of cropping of black boarder(0=no cropping, 100=no boarder left):", 50);
  		Dialog.show();
  		crop_percent=Dialog.getNumber();
  		}
  
	if(crop_choice=="no black boarder visible") crop_percent=1;
	else if(crop_choice== "minimum black boarder"||crop_choice== "minmimum black boarder (extreme value removed)")crop_percent=0;
	//else if(crop_choice=="two stacks:with and without boarder")crop_percent=0;
	else crop_percent=crop_percent/100;
	}

if(process_tempstat==true||process_databar==true){  
	if(time_choice=="personnalised"){
	  	Dialog.create("ESEM movie maker, personnalised time");
//	  	Dialog.addNumber("Year:", 2018);
	  	Dialog.addNumber("Month:", 07);
	  	Dialog.addNumber("Day:", 13);
	  	Dialog.addNumber("Hours (24h format):", 19);
	  	Dialog.addNumber("Minutes:", 40);
	  	Dialog.addNumber("Seconds:", 24);
	  	Dialog.show();

//	  	Year0 = Dialog.getNumber();
		Month0 = Dialog.getNumber();
		Day0 = Dialog.getNumber();
		Hours0 = Dialog.getNumber();
		Minutes0 = Dialog.getNumber();
		Seconds0 = Dialog.getNumber();
		t0=(60*Hours0+Minutes0)*60+Seconds0;//set the initial time
	  }
	  
	if(Temp_meas==false){
		Dialog.create("ESEM movie maker, personnalised temperature");
		Dialog.addMessage("It is assumed that the temperature followed \n a simple ramp up / dwell / ramp down program. ");
		Dialog.addNumber("Starting temperature [°C]:", 100);
		Dialog.addNumber("Temperature heating ramp [°C/min]:", 25);
		Dialog.addNumber("Dwell temperature [°C]:", 800);
		Dialog.addNumber("Dwell time [min]:", 60);
		Dialog.addNumber("Temperature cooling ramp [°C]:", 100);
		Dialog.addNumber("Final temperature [°C]:", 150);
		Dialog.addMessage("Heating beginning time :");
		Dialog.addNumber("Hour (24h format):", 16);
		Dialog.addNumber("Minute:", 03);
		Dialog.addNumber("Second:", 40);
		Dialog.show();

		StartT = Dialog.getNumber();
		Rampup = Dialog.getNumber();
		DwellT = Dialog.getNumber();
		Dwelltime = Dialog.getNumber();
		Rampdown = Dialog.getNumber();
		EndT = Dialog.getNumber();
		Starth = Dialog.getNumber();
		Startm = Dialog.getNumber();
		Starts = Dialog.getNumber();
	}
	
	if(gas==true){
		

		GasName=newArray(10);
		Gasintroh=newArray(10);
		Gasintrom=newArray(10);
		Gasintros=newArray(10);
		timegasintro=newArray(11);

		i=0;
		
		do{
			Dialog.create("ESEM movie maker, gas"+(i+1) +" use description");
			Dialog.addChoice("Gas name:", newArray("Oxygen","Hydrogen","Methan","Ethan","Carbon dioxide"));
			Dialog.addMessage("Gas introduction time (assuming the previous gas is switched off and all the experiment happen the same day):");
			Dialog.addNumber("Hour (24h format)", 00);
			Dialog.addNumber("Minute ", 00);
			Dialog.addNumber("Second ", 00);
			
			Dialog.addCheckbox("This is the last gas used for this experiment:",false);
			
			Dialog.show();
	
			GasName[i] = Dialog.getChoice();
			Gasintroh[i]=Dialog.getNumber();
			Gasintrom[i]=Dialog.getNumber();
			Gasintros[i]=Dialog.getNumber();
			lastgas=Dialog.getCheckbox();
			
			timegasintro[i]=(60*Gasintroh[i]+Gasintrom[i])*60+Gasintros[i];

			i++;
			if (i>9) exit ("This macro cannot handle more than 10 gases");
			if(lastgas) {
				numberofGas=i;
				timegasintro[numberofGas]=86401;
			}
	
		}while(!lastgas);
		
	}
}



// ******************************************** Opening and preparation ********************************************
if(process_databar==true && directory=="null") directory=getInfo("image.directory");
file_list=getFileList(directory);
firstimage=directory+"//"+file_list[1];

if(process_open==true)run("Image Sequence...", "open=["+firstimage+"] sort");


getDimensions(ImageWidth, height, channels, slices, frames);
originalheight=height-59;
originalwidth=ImageWidth;
number_of_images=nSlices;
number_of_stack=floor(number_of_images/parameterstack);
folder_name=getTitle();
nslices_substack=floor(number_of_images/(number_of_stack));
slices_adding=0;
	
//duplicate image zone

boarderx=2*boarder+originalwidth;
boardery=2*boarder+originalheight;

if(process_contrast==true&&process_duplicate==false){
	Stack.getStatistics(voxelCount, mean, min, max, stdDev)
	
	objmean=mean;
	objstd=stdDev;
	
	 for (i=1; i<=number_of_images; i++) {
	    setSlice(i);
		getStatistics(area, mean, min, max, std);
		shift=mean-objmean;
		span=255-255*(std/objstd);
		if(abs(shift)>1 || abs(span)>1){
			setMinAndMax(shift+span*(objmean/255), 255+shift-span*(1-objmean/255));
			run("Apply LUT", "slice");
			}
		}
	}
	
if(process_duplicate==true){
	selectWindow(folder_name);
	makeRectangle(0, 0, 1024, 884);
	run("Duplicate...", "title=[stackimages] duplicate range=1-"+number_of_images);
	
	newheight=884;
	boardery=2*boarder+newheight;

	if(process_contrast==true){
		Stack.getStatistics(voxelCount, mean, min, max, stdDev)
		
		objmean=mean;
		objstd=stdDev;
		
		 for (i=1; i<=number_of_images; i++) {
		    setSlice(i);
			getStatistics(area, mean, min, max, std);
			shift=mean-objmean;
			span=255-255*(std/objstd);
			if(abs(shift)>1&&abs(span)>1){
				setMinAndMax(shift+span*(objmean/255), 255+shift-span*(1-objmean/255));
				run("Apply LUT", "slice");
				}	
			}
		}
	
	run("Canvas Size...", "width="+boarderx+" height="+boardery+" position=Center"); //increase canvas size to avoid loss of information when aligning
	}

	

// ******************************************** Alignement ********************************************




if(process_align==true){
	
	substackimages="stackimages"; //name of the duplicated stack

	run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=1.60 steps_per_scale_octave=3 minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=4 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 maximal_alignment_error=25 inlier_ratio=0.05 expected_transformation=Affine interpolate");

	alignedstack="Aligned "+number_of_images+" of " +number_of_images;
	selectWindow(alignedstack);
	Stack.setSlice(1);
}
//Array.show("Results",xfromleft,yfromtop);

// ******************************************** Cropping ********************************************

 if(process_crop==true) {

	
	getDimensions(width, height, channels, slices, frames);
 	xfromleft=newArray(number_of_images);
	yfromtop=newArray(number_of_images);
	xfromright=newArray(number_of_images);
	yfrombottom=newArray(number_of_images);

	for (i = 0; i < number_of_images; i++) {
		max=0;
		xcrop=0;
		while(max==0){
			makeRectangle(0, 0, ++xcrop, height);
			getStatistics(area, mean, min, max);
		}
		xfromleft[i]=xcrop-1;
		if(xcrop-1==0) print("The alignment on left side reaches maximum: information may be lost.");
		
		max=0;
		xcrop=0;
		while(max==0){
			makeRectangle(width-(++xcrop), 0, xcrop, height);
			getStatistics(area, mean, min, max);
		}
		xfromright[i]=xcrop-1;
		if(xcrop-1==0) print("The alignment on right side reaches maximum: information may be lost.");
		
		max=0;
		ycrop=0;
		while(max==0){
			makeRectangle(0, 0, width, ++ycrop);
			getStatistics(area, mean, min, max);
		}
		yfromtop[i]=ycrop-1;
		if(ycrop-1==0) print("The alignment on top reaches maximum: information may be lost.");
		
		max=0;
		ycrop=0;
		while(max==0){
			makeRectangle(0, height-(++ycrop), width, ycrop);
			getStatistics(area, mean, min, max);
		}
		yfrombottom[i]=ycrop-1;
		if(ycrop-1==0) print("The alignment on bottom side reaches maximum: information may be lost.");
		
		run("Next Slice [>]");
	}


 	sortedxfromleft= Array.copy(xfromleft);
	sortedyfromtop= Array.copy(yfromtop);	
	sortedxfromright= Array.copy(xfromright);
	sortedyfrombottom= Array.copy(yfrombottom);	
	
	Array.sort(sortedxfromleft);
	Array.sort(sortedyfromtop);
	Array.sort(sortedxfromright);
	Array.sort(sortedyfrombottom);

	cutoff=4; //remove extreme value, here the first and last quarter
	firstdecilexl=sortedxfromleft[floor(number_of_images/cutoff)];
	firstdecileyt=sortedyfromtop[floor(number_of_images/cutoff)];
	ninthdecilexl=sortedxfromleft[floor(number_of_images*(cutoff-1)/cutoff)];
	ninthdecileyt=sortedyfromtop[floor(number_of_images*(cutoff-1)/cutoff)];
	
	firstdecilexr=sortedxfromleft[floor(number_of_images/cutoff)];
	firstdecileyb=sortedyfromtop[floor(number_of_images/cutoff)];
	ninthdecilexr=sortedxfromleft[floor(number_of_images*(cutoff-1)/cutoff)];
	ninthdecileyb=sortedyfromtop[floor(number_of_images*(cutoff-1)/cutoff)];
	
	Array.getStatistics(xfromleft, dXlmin, dXlmax);
	Array.getStatistics(yfromtop, dYtmin, dYtmax);
	Array.getStatistics(xfromright, dXrmin, dXrmax);
	Array.getStatistics(yfrombottom, dYbmin, dYbmax);
		
 	CropSize=newArray(2);
 	newwidth=originalwidth;
 	newheight=originalheight;
 	
 	if(crop_choice== "minmimum black boarder (extreme value removed)") {
 		if (firstdecilexl==0) dXmin=boarder-ninthdecilexr;
 		else dXmin=firstdecilexl;

 		dXmax=ninthdecilexl;
 		if (firstdecilexr==0)newwidth=originalwidth+boarder-ninthdecilexl;
 		
 		if (firstdecileyt!=0) dYmin=firstdecileyt;
 		else dYmin=boarder-ninthdecileyb;
 		
 		dYmax=ninthdecileyt;
 		if (firstdecileyb==0)newheight=originalheight+boarder-ninthdecileyt;
 	}
 	else {
 		if (dXlmin==0)  dXmin=boarder-dXrmax;
 		else dXmin=dXlmin;
 		
 		dXmax=dXlmax;
 		if (dXrmin==0)newwidth=originalwidth+boarder-dXlmax;
 		
 		if (dYtmin == 0) dYmin=boarder-dYbmax;
 		else dYmin=dYtmin;
 		
 		dYmax=dYtmax;
 		if (dYbmin==0)newheight=originalheight+boarder-dYtmax;
 	}

	// crop_percent = 0 to 1; 0 means 0% cropping (which means leave some black boarder), 1 means 100% cropping (no black boarder but some parts of the images removed
	CropSize[0]=newwidth+(1-crop_percent)*(dXmax-dXmin)+crop_percent*(dXmin-dXmax);
	CropSize[1]=newheight+(1-crop_percent)*(dYmax-dYmin)+crop_percent*(dYmin-dYmax);
	 
 	makeRectangle((1-crop_percent)*dXmin+crop_percent*dXmax,(1-crop_percent)*dYmin+crop_percent*dYmax,CropSize[0] ,CropSize[1] );
	run("Crop");
	getDimensions(ImageWidth, height, channels, slices, frames);
	databar_length=ImageWidth;
	
 }

//verif=newArray(originalwidth,originalheight, newwidth, newheight,dXmin,dXmax,dYmin,dYmax);
//Array.show(xfromleft,xfromright,yfromtop,yfrombottom,verif,CropSize);





// ******************************************** Make databar ********************************************
if(process_duplicate==true){
	substackimages=alignedstack; //name of the duplicated stack
	selectWindow(substackimages);}

selectWindow(folder_name);
path=firstimage;

//get information from stack
	
if(process_tempstat==true||process_databar==true){
		
	NumberofSlices=nSlices;
	Time=newArray(NumberofSlices);
	Temp=newArray(NumberofSlices);
	scale=newArray(NumberofSlices);
	Power=newArray(NumberofSlices);
	tandT=newArray(11);
	completetime=newArray(NumberofSlices);
	completedate=newArray(NumberofSlices);
	
	
	Stack.setSlice(1)
	
	
	if (time_choice=="from first image of stack"){
		tandT=GettandT(Temp_meas);
		Temp[0]=tandT[6];
		scale[0]=tandT[7];
		Power[0]=tandT[8];
		Year0=tandT[0];
		Month0=tandT[1];
		Day0=tandT[2];
		t0=(60*tandT[3]+tandT[4])*60+tandT[5];//set the initial time}
		Time[0]=0;
		completedate[0]=tandT[9];
		completetime[0]=tandT[10];
		firsttime=1;
		run("Next Slice [>]");
	 	} 
	 	else firsttime=0;	
		 	
	for(j=firsttime;j<NumberofSlices;j++){
		tandT=GettandT(Temp_meas);//run("GetTimeandTemp "); // run for the first slice.
		Year=tandT[0];
		Month=tandT[1];
		Day=tandT[2];
		if(Month!=Month0) exit ("Month changed, macro need to be improved to take that into account");
		tj=(60*tandT[3]+tandT[4])*60+tandT[5]+(Day-Day0)*86400;
		Time[j]=tj-t0;
		
		Temp[j]=tandT[6];
		scale[j]=tandT[7];
		Power[j]=tandT[8];	
		completedate[j]=tandT[9];
		completetime[j]=tandT[10];	
	
		run("Next Slice [>]");
	}

	if(Temp_meas==false){
		tr=(60*Starth+Startm)*60+Starts-t0;
		t1=tr+(DwellT-StartT)/Rampup*60;
		t2=t1+Dwelltime*60;
		tf=t2+(DwellT-EndT)/Rampdown*60;
		
		for(j=0;j<NumberofSlices;j++){
			if(Time[j]<=tr) Temp[j]=StartT;
			else if(Time[j]>tr&&Time[j]<=t1)Temp[j]=StartT+Rampup*(Time[j]-tr)/60;
			else if(Time[j]>t1&&Time[j]<=t2)Temp[j]=DwellT;
			else if(Time[j]>t2&&Time[j]<=tf)Temp[j]=DwellT-Rampdown*(Time[j]-t2)/60;
			else if(Time[j]>tf)Temp[j]=EndT;
			else Temp[j]=-400;
			
			}
	}

	}
	
  if(process_databar==true){
	
	ImageWidth=databar_length;
			
	//create databar and set up the option for writing

	if(ImageWidth>799)DatabarSize=floor(ImageWidth/200);
	else if (ImageWidth>419) DatabarSize=4;
	else if (ImageWidth>150) DatabarSize=3;// else if (ImageWidth>318) DatabarSize=3;
	//else if (ImageWidth>249) DatabarSize=2;
	//else if (ImageWidth>189) DatabarSize=1;
	else exit("video too small. Macro need improvement"); // look for re-arrangement of the databar

	if(gas==true) istheregas=1;
	else istheregas=0;
	
	newImage("databar-img1", "8-bit black",ImageWidth, (10+istheregas*4)*DatabarSize, NumberofSlices);
	setForegroundColor(255, 255, 255);
	setFont("SansSerif", 5*DatabarSize, " antialiased");
	setColor("white");
	
	//***** size of scale bar calculation********
	
	if(ImageWidth<350){
		temperaturestr="T : ";
		timestr="t : ";
		lengthtemp=24;
		spaceleft_param=3;}
			
	else{ 
		temperaturestr="Temperature: ";
		timestr="Time: ";
		lengthtemp=52;
		spaceleft_param=5;}
		
	// left space for databar
	SpaceLeft=ImageWidth-DatabarSize*95*spaceleft_param/5; //approximative space left for scalebar
	AvailableScale=newArray(500,200,100,50,20,10,5,2,1);
	ScaleBarLength=newArray(NumberofSlices);

	
		
	for(j=0;j<NumberofSlices;j++) {
		ScaleLength= SpaceLeft*scale[j]*pow(10, -Power[j]); // size of the maximum scalebar
		h=0;
		k=0;
		Meter=0;
		do {
	    	if(ScaleLength<AvailableScale[h]) h++; //comparison of the maximum scalebar with possible length
	    	else {
	     	ScaleBarLength[j]=AvailableScale[h]; //definition of the size of the scalebar
	     	k=1;
	     	}
	    	if(h==9 && k==0){h=0;ScaleLength=ScaleLength*1000;Meter++;}
	    } while (k==0);

		if(Meter==0) unit="m";
		else if(Meter==1) {unit="mm";Power[j]=Power[j]-3;}
		else if(Meter==2) {unit="um";Power[j]=Power[j]-6;}
		else if(Meter==3) {unit="nm"; Power[j]=Power[j]-9;}
		else if(Meter==4) {unit="pm";Power[j]=Power[j]-12;}
		else unit="too small";
	}

	if(timedisplay_choice=="h") {timediviser=3600; decimal=1;timeunit="h";}
	else if (timedisplay_choice=="min") {timediviser=60; decimal=0;timeunit="min";}
	else if (timedisplay_choice=="sec") {timediviser=1; decimal=0;timeunit="s";}


	//write temperature, time, scale and eventually gas in the databar
	k=0;

		
	for(j=0;j<NumberofSlices;j++){
		drawString(temperaturestr+d2s(Temp[j],0)+fromCharCode(176)+"C ", 2*DatabarSize, (7-istheregas)*DatabarSize);
		if(gas==true) { drawString("Gas: "+GasName[k], 2*DatabarSize, 12*DatabarSize);
			if(Time[j]>=(timegasintro[k+1]-t0))k++; }
		drawString(timestr+d2s(Time[j]/timediviser,decimal)+timeunit, lengthtemp*DatabarSize, (7-istheregas)*DatabarSize);
		run("Set Scale...", "distance=1 known="+d2s(scale[j]*pow(10, -Power[j]),15)+" pixel=1 unit="+unit);
		run("Scale Bar...", "width="+ScaleBarLength[j]+" height="+d2s(2*DatabarSize,0)+" font="+d2s(5*DatabarSize,0)+" color=White background=None location=[Lower Right]");
		
		run("Next Slice [>]");
		}
	
	//if(scaleUnit_choice=="millimeter"&&unit!="mm"||scaleUnit_choice=="micrometre"&&unit!="um"||scaleUnit_choice=="nanomater"&&unit!="nm"||) exit("Scale unit problem");
	//Set scale on all the databar slices
	
	if(timebar_choice=="yes"){
		lengthOfSec=ImageWidth/Time[NumberofSlices-1];
		newImage("databar-img2", "8-bit black",ImageWidth, 3*DatabarSize, NumberofSlices); //if wanted , possible to put color but have to convert the whole stack into RGVB
		setForegroundColor(255, 0, 0);
		
		if(Temp_meas==false){
			makeRectangle( floor(tr*lengthOfSec),0, floor((t1-tr)*lengthOfSec) ,3*DatabarSize);
		run("Fill", "stack");
		setForegroundColor(0, 0, 255);
		makeRectangle( floor(t2*lengthOfSec),0, floor((tf-t2)*lengthOfSec) ,3*DatabarSize);
		run("Fill", "stack");
		}
		
		setForegroundColor(255, 255, 255);
		setFont("SansSerif", 3*DatabarSize, "bold");
		
		for(j=0;j<NumberofSlices;j++){
			timebar=floor(Time[j]*lengthOfSec);
			if(timebar>0){
				makeRectangle(0,0.5*DatabarSize, timebar ,2*DatabarSize);
				run("Fill", "slice");
				}
				if(Temp_meas==false){
					if(getStringWidth("Heating")<floor((t1-tr)*lengthOfSec)) drawString("Heating",tr*lengthOfSec+floor(((t1-tr)*lengthOfSec-getStringWidth("heating"))/2),3*DatabarSize);
					if(getStringWidth("Dwelling")<floor((t1-tr)*lengthOfSec)) drawString("Dwelling",t1*lengthOfSec+floor(((t2-t1)*lengthOfSec-getStringWidth("heating"))/2),3*DatabarSize);
					if(getStringWidth("Cooling")<floor((tf-t2)*lengthOfSec)) drawString("Cooling",t2*lengthOfSec+floor(((tf-t2)*lengthOfSec-getStringWidth("heating"))/2),3*DatabarSize);
				}
			run("Next Slice [>]");
		}
	
		run("Combine...", "stack1=databar-img2 stack2=databar-img1 combine");
		selectWindow("Combined Stacks");
		rename("databar-img1");}

	

	if(process_duplicate==true){
		run("Combine...", "stack1=["+substackimages+"] stack2=databar-img1 combine");
	}
  }

if(process_tempstat==true){
	Array.getStatistics(Temp, Tmin, Tmax, Tmean, TstdDev);
	Temptot=Temp[0]*(Time[1]-Time[0]); //Assuming the first image has a scan time equal to the second image
	Timetot=Time[NumberofSlices-1];	
	for(j=1;j<NumberofSlices;j++){
	Temptot=Temptot+Temp[j]*(Time[j]-Time[j-1]);	
	}
	Tmean2=Temptot/Timetot;
	Temptotstd=pow((Temp[0]-Tmean2),2)*(Time[1]-Time[0]); // idem
	for(j=1;j<NumberofSlices;j++){
	Temptotstd=Temptotstd+pow((Temp[j]-Tmean2),2)*(Time[j]-Time[j-1]);	
	}
	TstdDev2=pow((Temptotstd/Timetot),0.5);
	Timeh=d2s(floor(Timetot/3600),0);
	Timemin=d2s(floor((Timetot-Timeh*3600)/60),0);
	Times=d2s(Timetot-Timeh*3600-Timemin*60,0);
	Timetotalstr=Timeh+"h "+Timemin+"min "+Times+"s ";
	Tstat=Array.concat(Tmin, Tmax, Tmean,Tmean2, TstdDev,TstdDev2,Timetotalstr);
	Tstatname=newArray("Minimum temperature", "Maximum temperature", "Average temperature", "Corrected Average temperature","Standard deviation","Corrected Standard deviation","Total time");
	Array.show("Result2",Tstatname, Tstat);
	Array.show("Results",completedate,completetime,Time,Temp);
	Plot.create("Temperature vs. time", "Time", "Temperature", Time, Temp);
	}




//*******************************************************Save the movie *****************************************************
//run("AVI... ", "compression=JPEG frame=6 save=[D:\\Stephane Poitel\\Documents\\Logiciels\\test\\images\\test.avi]");



//*********************************************Close everything ********************* (unless stated otherwise)

//selectWindow("Results");
//run("Close");
//selectWindow("Log");
//run("Close") 



print((getTime()-start)/1000);  

