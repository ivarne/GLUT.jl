# Tue 13 Nov 2012 04:13:36 PM EST 
#
# NeHe Tut 8 - Implement lights and rotate an alpha-blended, textured cube


# load necessary GLUT/GLU/OpenGL routines

require("GLUT")
using GLUT

### auxiliary functions

function cube(size)  # the cube function now includes surface normal specification for proper lighting
  glbegin(GL_QUADS)
    # Front Face
    glnormal(0.0,0.0,1.0)
    gltexcoord(0.0, 0.0)
    glvertex(-size, -size, size)
    gltexcoord(1.0, 0.0)
    glvertex(size, -size, size)
    gltexcoord(1.0, 1.0)
    glvertex(size, size, size)
    gltexcoord(0.0, 1.0)
    glvertex(-size, size, size)

    # Back Face
    glnormal(0.0,0.0,-1.0)
    gltexcoord(1.0, 0.0)
    glvertex(-size, -size, -size)
    gltexcoord(1.0, 1.0)
    glvertex(-size, size, -size)
    gltexcoord(0.0, 1.0)
    glvertex(size, size, -size)
    gltexcoord(0.0, 0.0)
    glvertex(size, -size, -size)

    # Top Face
    glnormal(0.0,1.0,0.0)
    gltexcoord(0.0, 1.0)
    glvertex(-size, size, -size)
    gltexcoord(0.0, 0.0)
    glvertex(-size, size, size)
    gltexcoord(1.0, 0.0)
    glvertex(size, size, size)
    gltexcoord(1.0, 1.0)
    glvertex(size, size, -size)

    # Bottom Face
    glnormal(0.0,-1.0,0.0)
    gltexcoord(1.0, 1.0)
    glvertex(-size, -size, -size)
    gltexcoord(0.0, 1.0)
    glvertex(size, -size, -size)
    gltexcoord(0.0, 0.0)
    glvertex(size, -size, size)
    gltexcoord(1.0, 0.0)
    glvertex(-size, -size, size)

    # Right Face
    glnormal(1.0,0.0,0.0)
    gltexcoord(1.0, 0.0)
    glvertex(size, -size, -size)
    gltexcoord(1.0, 1.0)
    glvertex(size, size, -size)
    gltexcoord(0.0, 1.0)
    glvertex(size, size, size)
    gltexcoord(0.0, 0.0)
    glvertex(size, -size, size)

    # Left Face
    glnormal(-1.0,0.0,0.0)
    gltexcoord(0.0, 0.0)
    glvertex(-size, -size, -size)
    gltexcoord(1.0, 0.0)
    glvertex(-size, -size, size)
    gltexcoord(1.0, 1.0)
    glvertex(-size, size, size)
    gltexcoord(0.0, 1.0)
    glvertex(-size, size, -size)
  glend()
end

### end of auxiliary functions

# initialize variables

global window

global light  = false
global blend  = false
global filter = 0

global xrot   = 0.0
global yrot   = 0.0
global xspeed = 0.0
global yspeed = 0.0

global tex    = Array(Uint8,3) # generating 3 textures

z             = -5.0

cube_size     = 1.0

width         = 640
height        = 480

LightAmbient  = [0.5, 0.5, 0.5, 1.0]
LightDiffuse  = [1.0, 1.0, 1.0, 1.0]
LightPosition = [0.0, 0.0, 2.0, 1.0]

# load textures from images

function LoadGLTextures()
    global tex
    img  = imread("glass.bmp")
    glgentextures(3,tex)

    glbindtexture(GL_TEXTURE_2D,tex[1])
    gltexparameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    gltexparameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glteximage2d(GL_TEXTURE_2D, 0, 3, size(img,1), size(img,2), 0, GL_RGB, GL_UNSIGNED_BYTE, img)

    glbindtexture(GL_TEXTURE_2D,tex[2])
    gltexparameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    gltexparameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glteximage2d(GL_TEXTURE_2D, 0, 3, size(img,1), size(img,2), 0, GL_RGB, GL_UNSIGNED_BYTE, img)

    glbindtexture(GL_TEXTURE_2D,tex[3])
    gltexparameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    gltexparameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST)
    glteximage2d(GL_TEXTURE_2D, 0, 3, size(img,1), size(img,2), 0, GL_RGB, GL_UNSIGNED_BYTE, img)

    glubuild2dmipmaps(GL_TEXTURE_2D, 3, size(img,1), size(img,2), GL_RGB, GL_UNSIGNED_BYTE, img)
end

# function to init OpenGL context

function initGL(w::Integer,h::Integer)
    glviewport(0,0,w,h)
    glclearcolor(0.0, 0.0, 0.0, 0.0)
    glcleardepth(1.0)			 
    gldepthfunc(GL_LESS)	 
    glenable(GL_DEPTH_TEST)
    glshademodel(GL_SMOOTH)

    # initialize lights
    gllightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient)
    gllightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse)
    gllightfv(GL_LIGHT1, GL_POSITION, LightPosition)

    glenable(GL_LIGHT1)

    # enable texture mapping
    glenable(GL_TEXTURE_2D)

    # enable alpha blending for textures
    glblendfunc(GL_SRC_ALPHA, GL_ONE)
    glcolor(1.0, 1.0, 1.0, 0.5)

    glmatrixmode(GL_PROJECTION)
    glloadidentity()

    gluperspective(45.0,w/h,0.1,100.0)

    glmatrixmode(GL_MODELVIEW)
end

# prepare Julia equivalents of C callbacks that are typically used in GLUT code

function ReSizeGLScene(w::Int32,h::Int32)
    if h == 0
        h = 1
    end

    glviewport(0,0,w,h)

    glmatrixmode(GL_PROJECTION)
    glloadidentity()

    gluperspective(45.0,w/h,0.1,100.0)

    glmatrixmode(GL_MODELVIEW)
end

_ReSizeGLScene = cfunction(ReSizeGLScene, Void, (Int32, Int32))

function DrawGLScene()
    global z
    global xrot
    global yrot
    global tex
    global filter
    global xspeed
    global yspeed
    global cube_size

    glclear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glloadidentity()

    gltranslate(0.0, 0.0, z)

    glrotate(xrot,1.0,0.0,0.0)
    glrotate(yrot,0.0,1.0,0.0)

    if filter == 0
        glbindtexture(GL_TEXTURE_2D,tex[1])
    elseif filter == 1
        glbindtexture(GL_TEXTURE_2D,tex[2])
    elseif filter == 2
        glbindtexture(GL_TEXTURE_2D,tex[3])
    end
    cube(cube_size)

    xrot +=xspeed
    yrot +=yspeed

    glutswapbuffers()
end
   
_DrawGLScene = cfunction(DrawGLScene, Void, ())

function keyPressed(key::Char,x::Int32,y::Int32)
    if key == int('q')
        glutdestroywindow(window)
    end
end

_keyPressed = cfunction(keyPressed, Void, (Char, Int32, Int32))

# run GLUT routines

glutinit([1], ["a"])
glutinitdisplaymode(GLUT_RGBA | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH)
glutinitwindowsize(width, height)
glutinitwindowposition(0, 0)

window = glutcreatewindow("NeHe Tut 8")

glutdisplayfunc(_DrawGLScene)
glutfullscreen()

glutidlefunc(_DrawGLScene)
glutreshapefunc(_ReSizeGLScene)
glutkeyboardfunc(_keyPressed)

initGL(width, height)

glutmainloop()
