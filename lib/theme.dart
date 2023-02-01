import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// RADIUS: Buttons, textField container => 16

class AppTheme {
  // 'appBarHeight' = 80,
  static ThemeData appTheme = ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xff071eff),
        // primary: const Color(0xff5181b8),
        secondary:
            const Color(0xff0058e4), // Color got the overflow glow effect
        tertiary: const Color(0xffe2e3e5),
        surface: const Color.fromRGBO(232, 233, 234, 1), // card color
        error: const Color(0xffe40031),
        outline: const Color(0xffd3d5d7),
        shadow:
            const Color(0xff838997) // Used for icons in buttonIcons and labels
        ),
    scrollbarTheme: ScrollbarThemeData().copyWith(
      thumbColor: MaterialStateProperty.all(const Color(0xff1f5cff)),
      trackColor: MaterialStateProperty.all(const Color(0xff212224)),
    ),
    brightness: Brightness.light,
    dividerColor: Color(0xffd5d6d8),
    useMaterial3: false,
    textTheme: appTextTheme,
    scaffoldBackgroundColor: const Color(0xffffffff),
    cardColor: const Color(0xfff2f3f5), // ✅
    primaryColor: const Color(0xff5181b8), // ✅
    hoverColor: const Color.fromARGB(255, 0, 0,
        0), // `InkWell` → Background color on tap. && `Button` → Background color on tap.
    buttonColor: const Color(0xffd3d5d7),
    // In the Inkwell Widget, splashColor is the color the appears like in waves (it gives the sensation of tap),
    //highlightColor appears when you long press the InkWell widget.
    // highlightColor is also defines the color for the scrollbar thumb.
    splashColor: const Color(0xffbfbfbf),
    highlightColor: const Color(0xffd3d5d7),
    accentColor: const Color(0xfff0f2f5), // Color got the overflow glow effect
    unselectedWidgetColor: const Color(0xffd9d9d9),
    focusColor: const Color(0xff148dc6),
    hintColor: const Color(0xff45cf69),
    errorColor: const Color(0xffC42C17), // ✅

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xfff2f3f5),
      elevation: 0,
      toolbarHeight: 80,
      titleTextStyle: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Colors.black),
    ),
  );

  static ThemeData appDarkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xff071eff),
        secondary:
            const Color(0xff0058e4), // Color got the overflow glow effect
        tertiary: const Color(0xff282828),
        surface: const Color(0xff212224),
        error: const Color(0xffe40031),
        outline: const Color(0xff333333),
        shadow: const Color(0xff838997)),
    scrollbarTheme: ScrollbarThemeData().copyWith(
      thumbColor: MaterialStateProperty.all(const Color(0xff54ff81)),
      trackColor: MaterialStateProperty.all(const Color(0xff212224)),
    ),
    brightness: Brightness.dark,
    useMaterial3: false,
    textTheme: appTextThemeDark,
    dividerColor: const Color(0xff333333), //✅
    // dividerColor: const Color(0xff202c45), //✅
    scaffoldBackgroundColor: const Color(0xff0f0f0f),
    cardColor: const Color(0xff212224),
    primaryColor: Color(0xff45cf69),
    // const Color(0xff4a98f7),
    hoverColor: const Color.fromARGB(255, 0, 0,
        0), // `InkWell` → Background color on tap. && `Button` → Background color on tap.
    buttonColor: const Color(0xff1a1a1a),

    // In the Inkwell Widget, splashColor is the color the appears like in waves (it gives the sensation of tap),
    //highlightColor appears when you long press the InkWell widget.
    // highlightColor is also defines the color for the scrollbar thumb.
    splashColor: const Color(0xffdcdcdc),
    highlightColor: const Color(0xff333333),
    accentColor:
        const Color(0xfff0f2f5), //✅ // Color got the overflow glow effect
    unselectedWidgetColor: const Color(0xffd9d9d9),
    focusColor: const Color(0xff148dc6),
    hintColor: const Color(0xff45cf69),
    errorColor: const Color(0xffC42C17), //✅

    appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        )),
  );

  static TextTheme appTextTheme = TextTheme(
    headline1: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 26,
        color: Color(0xff242a2f),
        letterSpacing: 0.3,
        height: 0.9,
        fontWeight: FontWeight.w600),
    headline2: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 24,
        color: Color(0xff242a2f),
        fontWeight: FontWeight.w600),
    headline3: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 22,
        color: Color(0xff242a2f),
        fontWeight: FontWeight.w500),
    headline4: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 20,
        color: Color(0xff242a2f),
        fontWeight: FontWeight.w500),
    headline5: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: Colors.black),
    headline6: TextStyle(
        fontFamily: 'inputmono',
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
      color: Color(0xff242a2f),
    ),
    overline: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
        color: const Color(0xff444547)),
  );

  static TextTheme appTextThemeDark = TextTheme(
    headline1: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 26,
        color: Color(0xffeeeeee),
        letterSpacing: 0.3,
        height: 0.9,
        fontWeight: FontWeight.w600),
    headline2: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 24,
        color: Color(0xffeeeeee),
        fontWeight: FontWeight.w600),
    headline3: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 22,
        color: Color(0xffcecece),
        fontWeight: FontWeight.w500),
    headline4: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 20,
        color: Color(0xffcecece),
        fontWeight: FontWeight.w500),
    headline5: TextStyle(
        fontFamily: 'inputmono',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: Color(0xffcecece)),
    headline6: TextStyle(
        fontFamily: 'inputmono',
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
      color: const Color(0xffeeeeee),
    ),
    overline: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.2,
      color: Color(0xff878787),
    ),
  );
}
