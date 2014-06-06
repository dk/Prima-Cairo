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
surface_create(sv,attributes)
	SV *sv
	HV *attributes
PREINIT:
	Handle object;
	Handle context;
	GLRequest request;
	Bool need_paint_state = 0;
CODE:
	RETVAL = 0;
	
	if ( !(object = gimme_the_mate(sv)))
		croak("not a object");

	parse( &request, attributes);
	if ( kind_of( object, CApplication)) {
		request. target = GLREQ_TARGET_APPLICATION;
		need_paint_state = 1;
	}
	else if ( kind_of( object, CWidget))
		request. target = GLREQ_TARGET_WINDOW;
	else if ( kind_of( object, CDeviceBitmap)) 
		request. target = GLREQ_TARGET_BITMAP;
	else if ( kind_of( object, CImage)) {
		request. target = GLREQ_TARGET_IMAGE;
		need_paint_state = 1;
	}
	else if ( kind_of( object, CPrinter)) {
		request. target = GLREQ_TARGET_PRINTER;
		need_paint_state = 1;
	}
	else
		croak("bad object");

	if ( need_paint_state && !PObject(object)-> options. optInDraw )
		croak("object not in paint state");
	context = gl_context_create(object, &request);

	RETVAL = newSViv(context);
OUTPUT:
	RETVAL

void
context_destroy(context)
	void *context
CODE:
	if ( context) gl_context_destroy((Handle) context);


int
context_make_current(context)
	void *context
CODE:
	RETVAL = gl_context_make_current((Handle) context);
OUTPUT:
	RETVAL

int
context_push()
CODE:
	RETVAL = gl_context_push();
OUTPUT:
	RETVAL

int
context_pop()
CODE:
	RETVAL = gl_context_pop();
OUTPUT:
	RETVAL

int
flush(context)
	void *context
CODE:
	RETVAL = context ? gl_flush((Handle) context) : 0;
OUTPUT:
	RETVAL

SV *
last_error()
PREINIT:
	char buf[1024], *ret;
CODE:

	ret = gl_error_string(buf, 1024);
	RETVAL = ret ? newSVpv(ret, 0) : &PL_sv_undef;
OUTPUT:
	RETVAL

