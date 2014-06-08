#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Drawable.h>
#include <unix/guts.h>

#define Drawable        XDrawable
#include <cairo.h>
#include <cairo-xlib.h>
#include "prima_cairo.h"

#ifdef __cplusplus
extern "C" {
#endif

#define var (( PDrawable) widget)
#define sys (( PDrawableSysData) var-> sysData)

UnixGuts * pguts;

void*
apc_cairo_surface_create( Handle widget, int request)
{
	cairo_surface_t * result = NULL;
	if ( pguts == NULL )
		pguts = (UnixGuts*) apc_system_action("unix_guts");

	XCHECKPOINT;

	switch ( request) {
	case REQ_TARGET_PRINTER:
		break;
	case REQ_TARGET_BITMAP:
		result = cairo_xlib_surface_create_for_bitmap(DISP, sys->gdrawable, ScreenOfDisplay(DISP,SCREEN), var->w, var->h);
		break;
	default:
		result = cairo_xlib_surface_create(DISP, sys->gdrawable, VISUAL, var->w, var->h);
	}
	
	XCHECKPOINT;

	return (void*) result;
}


#ifdef __cplusplus
}
#endif

