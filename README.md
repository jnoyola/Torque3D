# Torque 3D Win64/OSX10.10 Multiplayer Compatible

Recast, Navigation Meshes, and the related parts of AIPlayer have been removed for compatibility.

* For building on Windows, TORQUE_NAVIGATION_ENABLED must be removed from the preprocessor definitions list (Properties -> Configuration Properties -> C/C++ -> Preprocessor -> Preprocessor Definitions)
* For building on OS X, gfx/gl/osx/gfxGLDevice.mac.mm and gui/core/guiOffscreenCanvas.ccp/h must be included in the project manually

MIT Licensed Open Source version of [Torque 3D](http://torque3d.org) from [GarageGames](http://www.garagegames.com)

## PhysX

* Windows
    1. Follow instructions on the [wiki](http://wiki.torque3d.org/coder:physx-setup)
    2. Enable preprocessor definitions TORQUE_PHYSICS_PHYSX3 and TORQUE_PHYSICS_ENABLED
    3. PhysX 3.3.2 for Windows only supports up to vc11.0 (requiring Visual Studio 2012). This can be changed in Properties -> Configuration Properties -> General -> Platform Toolset. This also requires the preprocessor flag _VARIADIC_MAX=10.
* OS X
    1. Follow instructions on the [wiki](http://wiki.torque3d.org/coder:physx-setup) up to step 2.4
    2. Add the path to the PhysX Include directory to Header Search Paths for Bundle.xcodeproj and set it to recursive
    3. Add the preprocessor definitions for step 2.8. (_DEBUG, NDEBUG) as well as TORQUE_PHYSICS_PHYSX3 and TORQUE_PHYSICS_ENABLED to Bundle.xcodeproj
    4. Add all libs (either checked or release) to Bundle.xcodeproj/Dependecies/builtLibs
    5. Changes to physx/Include/extensions/PxDefaultErrorCallback.h (only LLVM seems to require these)
        * 53: __virtual__ ~PxDefaultErrorCallback() __{}__;
        * 55: [...] __= 0__;

## More Information

* [Homepage](http://torque3d.org)
* [Torque 3D wiki](http://wiki.torque3d.org)
* [Community forum](http://forums.torque3d.org)
* [GarageGames forum](http://www.garagegames.com/community/forums)
* [GarageGames professional services](http://services.garagegames.com/)

## Pre-compiled Version

In addition to GitHub we also have a couple of pre-packaged files for you to download if you would prefer to not compile the code yourself.
They are available from the [downloads](http://wiki.torque3d.org/main:downloads) page on the wiki.

## Related repositories

* [Torque 3D main repository](https://github.com/GarageGames/Torque3D)
* [Project Manager repository](https://github.com/GarageGames/Torque3D-ProjectManager)
* [Offline documentation repository](https://github.com/GarageGames/Torque3D-Documentation)

# License

    Copyright (c) 2012 GarageGames, LLC

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
