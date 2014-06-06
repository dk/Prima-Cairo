#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Drawable.h>
#include <unix/guts.h>

#define Drawable        XDrawable
#define Font            XFont
#define Window          XWindow
#include <cairo.h>
#include <cairo-xlib.h>
#include "prima_cairo.h"

#ifdef __cplusplus
extern "C" {
#endif

#define var (( PComponent) widget)
#define ctx (( Context*) context)
#define sys (( PDrawableSysData) var-> sysData)

UnixGuts * pguts;

void*
apc_cairo_surface_create( Handle widget, int request)
{
	Point p;
	if ( pguts == NULL )
		pguts = (UnixGuts*) apc_system_action("unix_guts");

	XCHECKPOINT;

	switch ( request) {
	case REQ_TARGET_WINDOW:
		p = apc_widget_get_size( widget );
		return cairo_xlib_surface_create(DISP, sys->gdrawable, VISUAL, p.x, p.y);
	}

	return 0;
}


#ifdef __cplusplus
}
#endif

