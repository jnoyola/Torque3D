//-----------------------------------------------------------------------------
// Copyright (c) 2013 GarageGames, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rightsgfxG to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//-----------------------------------------------------------------------------
 
#import "platform/platform.h"
#import "platformMac/platformMacCarb.h"
#import "platformMac/osxFont.h"
#include "console/console.h"
#include <vector>
#include <string>

//------------------------------------------------------------------------------

PlatformFont* createPlatformFont( const char* name, dsize_t size, U32 charset )
{
    PlatformFont* pFont = new OSXFont();
    
    if ( pFont->create(name, size, charset) )
        return pFont;
    
    delete pFont;
    
    return NULL;
}

//------------------------------------------------------------------------------

OSXFont::OSXFont()
{
    // Reset the rendering color-space.
    mColorSpace = NULL;
}

//------------------------------------------------------------------------------

OSXFont::~OSXFont()
{
    // Destroy the rendering color-space.
    CGColorSpaceRelease( mColorSpace );
}

//------------------------------------------------------------------------------

bool OSXFont::create( const char* name, dsize_t size, U32 charset )
{
    // Sanity!
    AssertFatal( name != NULL, "Cannot create a NULL font name." );

    // Generate compatible font name.
    CFStringRef fontName = CFStringCreateWithCString( kCFAllocatorDefault, name, kCFStringEncodingUTF8 );

    // Sanity!
    if ( !fontName )
    {
        Con::errorf("Could not handle font name of '%s'.", name );
        return false;
    }

    // Use Windows as a baseline (96 DPI) and adjust accordingly.
    F32 scaledSize = size * (72.0f/96.0f);
    scaledSize = mRound(scaledSize);

    // Create the font reference.
    mFontRef = CTFontCreateWithName( fontName, scaledSize, NULL );

    // Sanity!
    if ( !mFontRef )
    {
        Con::errorf( "Could not generate a font reference to font name '%s' of size '%d'", name, size );
        return false;
    }

    // Fetch font metrics.
    CGFloat ascent = CTFontGetAscent( mFontRef );
    CGFloat descent = CTFontGetDescent( mFontRef );

    // Set baseline.
    mBaseline = (U32)mRound(ascent);

    // Set height.
    mHeight = (U32)mRound( ascent + descent );

    // Create a gray-scale color-space.
    mColorSpace = CGColorSpaceCreateDeviceGray();

    // Return status.
    return true;
}

//------------------------------------------------------------------------------

bool OSXFont::isValidChar( const UTF8* str ) const
{
    // since only low order characters are invalid, and since those characters
    // are single codeunits in UTF8, we can safely cast here.
    return isValidChar((UTF16)*str);
}

//------------------------------------------------------------------------------

bool OSXFont::isValidChar( const UTF16 character) const
{
    // We cut out the ASCII control chars here. Only printable characters are valid.
    // 0x20 == 32 == space
    if( character < 0x20 )
        return false;
    
    return true;
}

std::wstring utf8_to_utf16(const std::string& utf8)
{
    std::vector<unsigned long> unicode;
    size_t i = 0;
    while (i < utf8.size())
    {
        unsigned long uni;
        size_t todo;
        bool error = false;
        unsigned char ch = utf8[i++];
        if (ch <= 0x7F)
        {
            uni = ch;
            todo = 0;
        }
        else if (ch <= 0xBF)
        {
            Con::printf("not a UTF-8 string");
        }
        else if (ch <= 0xDF)
        {
            uni = ch&0x1F;
            todo = 1;
        }
        else if (ch <= 0xEF)
        {
            uni = ch&0x0F;
            todo = 2;
        }
        else if (ch <= 0xF7)
        {
            uni = ch&0x07;
            todo = 3;
        }
        else
        {
            Con::printf("not a UTF-8 string");
        }
        for (size_t j = 0; j < todo; ++j)
        {
            if (i == utf8.size())
                Con::printf("not a UTF-8 string");
            unsigned char ch = utf8[i++];
            if (ch < 0x80 || ch > 0xBF)
                Con::printf("not a UTF-8 string");
            uni <<= 6;
            uni += ch & 0x3F;
        }
        if (uni >= 0xD800 && uni <= 0xDFFF)
            Con::printf("not a UTF-8 string");
        if (uni > 0x10FFFF)
            Con::printf("not a UTF-8 string");
        unicode.push_back(uni);
    }
    std::wstring utf16;
    for (size_t i = 0; i < unicode.size(); ++i)
    {
        unsigned long uni = unicode[i];
        if (uni <= 0xFFFF)
        {
            utf16 += (wchar_t)uni;
        }
        else
        {
            uni -= 0x10000;
            utf16 += (wchar_t)((uni >> 10) + 0xD800);
            utf16 += (wchar_t)((uni & 0x3FF) + 0xDC00);
        }
    }
    return utf16;
}

//------------------------------------------------------------------------------

PlatformFont::CharInfo& OSXFont::getCharInfo(const UTF8 *str) const
{
    return getCharInfo( (UTF16)utf8_to_utf16(str).c_str()[0] );
}

//------------------------------------------------------------------------------

PlatformFont::CharInfo& OSXFont::getCharInfo(const UTF16 character) const
{
    // Declare and clear out the CharInfo that will be returned.
    static PlatformFont::CharInfo characterInfo;
    dMemset(&characterInfo, 0, sizeof(characterInfo));
    
    // prep values for GFont::addBitmap()
    characterInfo.bitmapIndex = 0;
    characterInfo.xOffset = 0;
    characterInfo.yOffset = 0;

    CGGlyph characterGlyph;
    CGRect characterBounds;
    CGSize characterAdvances;
    UniChar unicodeCharacter = character;

    // Fetch font glyphs.
    if ( !CTFontGetGlyphsForCharacters( mFontRef, &unicodeCharacter, &characterGlyph, (CFIndex)1) )
    {
        // Sanity!
        AssertFatal( false, "Cannot create font glyph." );
    }

    // Fetch glyph bounding box.
    CTFontGetBoundingRectsForGlyphs( mFontRef, kCTFontHorizontalOrientation, &characterGlyph, &characterBounds, (CFIndex)1 );

    // Fetch glyph advances.
    CTFontGetAdvancesForGlyphs( mFontRef, kCTFontHorizontalOrientation, &characterGlyph, &characterAdvances, (CFIndex)1 );

    // Set character metrics,
    characterInfo.xOrigin = (S32)mRound( characterBounds.origin.x );
    characterInfo.yOrigin = (S32)mRound( characterBounds.origin.y );
    characterInfo.width = (U32)mCeil( characterBounds.size.width ) + 2;
    characterInfo.height = (U32)mCeil( characterBounds.size.height ) + 2;
    characterInfo.xIncrement = (S32)mRound( characterAdvances.width );

    // Finish if character is undrawable.
    if ( characterInfo.width == 0 && characterInfo.height == 0 )
        return characterInfo;

    // Clamp character minimum width.
    if ( characterInfo.width == 0 )
        characterInfo.width = 2;

    if ( characterInfo.height == 0 )
        characterInfo.height = 1;


    // Allocate a bitmap surface.
    const U32 bitmapSize = characterInfo.width * characterInfo.height;
    characterInfo.bitmapData = new U8[bitmapSize];
    dMemset(characterInfo.bitmapData, 0x00, bitmapSize);

    // Create a bitmap context.
    CGContextRef bitmapContext = CGBitmapContextCreate( characterInfo.bitmapData, characterInfo.width, characterInfo.height, 8, characterInfo.width, mColorSpace, kCGImageAlphaNone );

    // Sanity!
    AssertFatal( bitmapContext != NULL, "Cannot create font context." );

    // Render font anti-aliased if font is arbitrarily small.
    CGContextSetShouldAntialias( bitmapContext, true);
    CGContextSetShouldSmoothFonts( bitmapContext, true);
    CGContextSetRenderingIntent( bitmapContext, kCGRenderingIntentAbsoluteColorimetric);
    CGContextSetInterpolationQuality( bitmapContext, kCGInterpolationNone);
    CGContextSetGrayFillColor( bitmapContext, 1.0, 1.0);
    CGContextSetTextDrawingMode( bitmapContext,  kCGTextFill);

    // Draw glyph. 
    CGPoint renderOrigin;
    renderOrigin.x = -characterInfo.xOrigin;
    renderOrigin.y = -characterInfo.yOrigin;
    
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    CTFontDrawGlyphs( mFontRef, &characterGlyph, &renderOrigin, 1, bitmapContext );
#else
    CGFontRef cgFont = CTFontCopyGraphicsFont(mFontRef, NULL);
    CGContextSetFont(bitmapContext, cgFont);
    CGContextSetFontSize(bitmapContext, CTFontGetSize(mFontRef));
    CGContextShowGlyphsAtPositions(bitmapContext, &characterGlyph, &renderOrigin, 1);
    CFRelease(cgFont);
#endif
    
     
 #if 0
    Con::printf("Width:%f, Height:%f, OriginX:%f, OriginY:%f",
            characterBounds.size.width,
            characterBounds.size.height,
            characterBounds.origin.x,
            characterBounds.origin.y );
#endif

    // Adjust the y origin for the glyph size.
    characterInfo.yOrigin += characterInfo.height;// + mHeight;

    // Release the bitmap context.
    CGContextRelease( bitmapContext );

    // Return character information.
    return characterInfo;
}