# RFont-Odin
![logo](logo.png)

# About
Odin bindings for RFont 

# example

## a very simple example
```odin
package RSGLApp
import RGFW "RGFW-Odin"
import RSGL "RSGL-Odin"

import "core:fmt"

main :: proc() {
   RGFW.init("RSGL-Odin", .initOpenGL);
   defer RGFW.deinit();
  
   window := RGFW.createWindow("Odin Window", 0, 0, 500, 500, .windowCenter | .windowOpenGL); 
   defer RGFW.window_close(window);

   renderer := RSGL.renderer_init(RSGL.GL_rendererProc(), rawptr(RGFW.getProcAddress_OpenGL));
   defer RSGL.renderer_free(renderer); 

   RSGL.renderer_updateSize(renderer, 500, 500);
   
   for (RGFW.window_shouldClose(window) == false) {
      RGFW.pollEvents(); 

      RSGL.renderer_clear(renderer, RSGL.RGB(255, 0, 0));
      RSGL.renderer_setColor(renderer, RSGL.RGB(0, 255 , 0));
      RSGL.drawRect(renderer, {200, 200, 200, 200});
      RSGL.renderer_render(renderer);

      RGFW.window_swapBuffers_OpenGL(window);
   }
}
```