#ifdef __cplusplus
extern "C" {
#endif

#define REQ_TARGET_APPLICATION 0
#define REQ_TARGET_WINDOW      1
#define REQ_TARGET_BITMAP      2
#define REQ_TARGET_IMAGE       3
#define REQ_TARGET_PRINTER     4

void*
apc_cairo_surface_create( Handle widget, int request);

#ifdef __cplusplus
}
#endif

