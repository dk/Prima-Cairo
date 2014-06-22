#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <DeviceBitmap.h>
#include <Widget.h>
#include <Image.h>
#include <Application.h>
#include <Printer.h>
#include "prima_cairo.h"
#include <cairo.h>

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

void
copy_image_data(im,s,direction)
	SV * im;
	UV s;
	int direction;
PREINIT:
	Handle image;
	int i, w, h, dest_stride, src_stride, stride, selector, cformat;
	Byte *dest_buf, *src_buf;
	cairo_surface_t * surface;
CODE:
	surface = INT2PTR(cairo_surface_t*,s);
	dest_stride = cairo_image_surface_get_stride(surface);
	dest_buf    = cairo_image_surface_get_data(surface);
	cformat     = cairo_image_surface_get_format(surface);

	if ( !(image = gimme_the_mate(im)) || !kind_of( image, CImage))
		croak("bad object");
	switch (PImage(image)->type) {
	case imBW:
		if ( cformat != CAIRO_FORMAT_A1 ) croak("bad object");
		break;
	case imByte:
		if ( cformat != CAIRO_FORMAT_A8 ) croak("bad object");
		break;
	case imRGB:
		if ( cformat != CAIRO_FORMAT_ARGB32 && cformat != CAIRO_FORMAT_RGB24) croak("bad object");
		break;

	}

	w   	   = PImage(image)->w;
	h   	   = PImage(image)->h;
	src_stride = PImage(image)->lineSize;
	src_buf    = PImage(image)->data + src_stride * ( h - 1);
	stride     = ( src_stride > dest_stride ) ? dest_stride : src_stride;
	selector   = (PImage(image)->type & imBPP) + (direction ? 100 : 0);
	for ( i = 0; i < h; i++, src_buf -= src_stride, dest_buf += dest_stride ) {
		switch(selector) {
		case 1:
			memcpy(dest_buf, src_buf, stride);
			break;
		case 8:
			memcpy(dest_buf, src_buf, w);
			break;
		case 24:
			bc_rgbi_rgb(dest_buf, src_buf, w);
			break;
		case 101:
			memcpy(src_buf, dest_buf, stride);
			break;
		case 108:
			memcpy(src_buf, dest_buf, w);
			break;
		case 124:
			bc_rgb_rgbi(src_buf, dest_buf, w);
			break;
		}
	}
OUTPUT:	

SV*
surface_create(sv)
	SV *sv
PREINIT:
	Handle object;
	void* context;
	int request;
	Bool need_paint_state = 0;
CODE:
	RETVAL = 0;
	
	if ( !(object = gimme_the_mate(sv)))
		croak("not a object");

	if ( kind_of( object, CApplication)) {
		request = REQ_TARGET_APPLICATION;
		need_paint_state = 1;
	}
	else if ( kind_of( object, CWidget))
		request = REQ_TARGET_WINDOW;
	else if ( kind_of( object, CDeviceBitmap)) 
		request = ((PDeviceBitmap)object)->monochrome ? REQ_TARGET_BITMAP : REQ_TARGET_PIXMAP;
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
	context = apc_cairo_surface_create(object, request);

	RETVAL = newSV(0);
	sv_setref_pv(RETVAL, "Prima::Cairo::Surface", context);
OUTPUT:
	RETVAL

