import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// RADIUS: Buttons, textField container => 16

class AppTheme {
  // 'appBarHeight' = 80,
  static ThemeData appTheme = ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xff071eff),
        secondary:
            const Color(0xff0058e4), // Color got the overflow glow effect
        /// Used just for icons
        tertiary: const Color(0xff22272f),
        surface: const Color(0xffe0e1e2), // card color
        surfaceVariant: const Color(0xffe8e9ea),
        error: const Color(0xffe40031),
        outline: const Color(0xffe7e8ec),
        shadow:
            const Color(0xff838997) // Used for icons in buttonIcons and labels
        ),
    scrollbarTheme: ScrollbarThemeData().copyWith(
      // thumbColor: MaterialStateProperty.all(appTheme.primaryColor),
      trackColor: MaterialStateProperty.all(const Color(0xff212224)),
    ),
    brightness: Brightness.light,
    dividerColor:
        Colors.transparent, // Color by default of separation lines in tables
    useMaterial3: false,
    textTheme: appTextTheme,
    scaffoldBackgroundColor: const Color(0xfff2f3f5),
    hoverColor: const Color.fromARGB(255, 0, 0,
        0), // `InkWell` → Background color on tap. && `Button` → Background color on tap.
    buttonColor: const Color(0xffd3d5d7),
    // In the Inkwell Widget, splashColor is the color the appears like in waves (it gives the sensation of tap),
    //colorScheme.surfaceVariant appears when you long press the InkWell widget.
    // colorScheme.surfaceVariant is also defines the color for the scrollbar thumb.
    splashColor: const Color(0xffbfbfbf),
    accentColor: const Color(0xfff0f2f5), // Color got the overflow glow effect
    unselectedWidgetColor: const Color(0xffd9d9d9),
    focusColor: const Color(0xff148dc6),
    hintColor: const Color(0xff45cf69),
  );

  static ThemeData appDarkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xff071eff),
      secondary: const Color(0xff0058e4),
      tertiary: const Color(0xffe8eaed),
      // ⬇ Used for cards (important sections containers)
      surface: const Color(0xff282828),
      surfaceVariant: const Color(0xff181818), // Used in text input background
      outline: const Color(0xff333333),
      error: const Color(0xffe40031),
      shadow: const Color(0xff838997),
    ),

    scrollbarTheme: ScrollbarThemeData().copyWith(
      // thumbColor: MaterialStateProperty.all(appDarkTheme.primaryColor),
      trackColor: MaterialStateProperty.all(const Color(0xff212224)),
    ),
    brightness: Brightness.dark,
    useMaterial3: false,
    textTheme: appTextThemeDark,
    dividerColor: Colors.transparent,
    scaffoldBackgroundColor: const Color(0xff121212),
    hoverColor: const Color.fromARGB(255, 0, 0,
        0), // `InkWell` → Background color on tap. && `Button` → Background color on tap.
    buttonColor: const Color(0xff1a1a1a),

    // In the Inkwell Widget, splashColor is the color the appears like in waves (it gives the sensation of tap),
    //colorScheme.surfaceVariant appears when you long press the InkWell widget.
    // colorScheme.surfaceVariant is also defines the color for the scrollbar thumb.
    splashColor: const Color(0xffdcdcdc),
    accentColor:
        const Color(0xfff0f2f5), //✅ // Color got the overflow glow effect
    unselectedWidgetColor: const Color(0xffd9d9d9),
    focusColor: const Color(0xff148dc6),
    hintColor: const Color(0xff45cf69),
  );

  static TextTheme appTextTheme = TextTheme(
    headline1: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 26,
        color: Color(0xff242a2f),
        letterSpacing: 0.3,
        height: 0.9,
        fontWeight: FontWeight.w600),
    headline2: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 24,
        color: Color(0xff242a2f),
        fontWeight: FontWeight.w600),
    headline3: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 22,
        color: Color(0xff242a2f),
        fontWeight: FontWeight.w500),
    headline4: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 20,
        color: Color(0xff242a2f),
        fontWeight: FontWeight.w500),
    headline5: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: Colors.black),
    headline6: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: Colors.black),
    bodyText1: GoogleFonts.roboto(
      color: Color(0xff242a2f),
      fontSize: 17,
    ),
    bodyText2: GoogleFonts.roboto(
      fontSize: 16,
      color: const Color(0xff7a7575),
    ),
    button: GoogleFonts.roboto(
      fontSize: 17,
      color: Colors.white,
      letterSpacing: 1.25,
      fontWeight: FontWeight.w600,
    ),
    caption: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: Color(0xffadadad),
    ),
    overline: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
        color: const Color(0xff444547)),
  );

  static TextTheme appTextThemeDark = TextTheme(
    headline1: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 26,
        color: Color(0xffeeeeee),
        letterSpacing: 0.3,
        height: 0.9,
        fontWeight: FontWeight.w600),
    headline2: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 24,
        color: Color(0xffeeeeee),
        fontWeight: FontWeight.w600),
    headline3: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 22,
        color: Color(0xffcecece),
        fontWeight: FontWeight.w500),
    headline4: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 20,
        color: Color(0xffcecece),
        fontWeight: FontWeight.w500),
    headline5: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: Color(0xffcecece)),
    headline6: TextStyle(
        fontFamily: 'oceanwide',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: Color(0xffcecece)),
    bodyText1: GoogleFonts.roboto(
      color: Color(0xffeeeeee),
      fontSize: 17,
    ),
    bodyText2: GoogleFonts.roboto(
      fontSize: 16,
      color: Color(0xff878787),
    ),
    button: GoogleFonts.roboto(
      fontSize: 17,
      color: Colors.white,
      letterSpacing: 1.25,
      fontWeight: FontWeight.w600,
    ),
    caption: GoogleFonts.roboto(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: const Color(0xffadadad),
    ),
    overline: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.2,
      color: Color(0xff878787),
    ),
  );
}
