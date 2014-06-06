#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <DeviceBitmap.h>
#include <Widget.h>
#include <Image.h>
#include <Application.h>
#include <Printer.h>
#include "prima_cairo.h"

PWidget_vmt CWidget;
PDeviceBitmap_vmt CDeviceBitmap;
PImage_vmt CImage;
PApplication_vmt CApplication;
PPrinter_vmt CPrinter;
#define var (( PWidget) widget)

MODULE = Prima::Cairo      PACKAGE = Prima::Cairo

BOOT:
{
	PRIMA_VERSION_BOOTCHECK;
	CWidget = (PWidget_vmt)gimme_the_vmt( "Prima::Widget");
	CDeviceBitmap = (PDeviceBitmap_vmt)gimme_the_vmt( "Prima::DeviceBitmap");
	CImage = (PImage_vmt)gimme_the_vmt( "Prima::Image");
	CApplication = (PApplication_vmt)gimme_the_vmt( "Prima::Application");
	CPrinter = (PPrinter_vmt)gimme_the_vmt( "Prima::Printer");
}

PROTOTYPES: ENABLE

SV*
surface_create(sv,sv)
	SV *sv
	SV *cairo_surface
PREINIT:
	Handle object;
	Handle context;
	int request;
	Bool need_paint_state = 0;
CODE:
	RETVAL = 0;
	
	if ( !(object = gimme_the_mate(sv)))
		croak("not a object");

	parse( &request, attributes);
	if ( kind_of( object, CApplication)) {
		request = REQ_TARGET_APPLICATION;
		need_paint_state = 1;
	}
	else if ( kind_of( object, CWidget))
		request = REQ_TARGET_WINDOW;
	else if ( kind_of( object, CDeviceBitmap)) 
		request = REQ_TARGET_BITMAP;
	else if ( kind_of( object, CImage)) {
		request = REQ_TARGET_IMAGE;
		need_paint_state = 1;
	}
	else if ( kind_of( object, CPrinter)) {
		request = REQ_TARGET_PRINTER;
		need_paint_state = 1;
	}
	else
		croak("bad object");

	if ( need_paint_state && !PObject(object)-> options. optInDraw )
		croak("object not in paint state");
	context = apc_cairo_surface_select(object, request);

	RETVAL = newSViv(context);
OUTPUT:
	RETVAL

