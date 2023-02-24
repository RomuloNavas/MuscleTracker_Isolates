# neuro_sdk_isolate_example

Demonstrates how to use the neuro_sdk_isolate plugin.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



in function showCountrySelectorBottomSheet()



 return Directionality(
                  textDirection: Directionality.of(inheritedContext),
                  child: Container(
                    decoration: ShapeDecoration(
                      color: Color(0xff242424),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(0),
                        ),
                      ),
                    ),

in countries_search_list_widget.dart
                    InputDecoration getSearchBoxDecoration() {
    return widget.searchBoxDecoration ??
        InputDecoration(
          labelText: 'Search by country name or dial code',
          labelStyle: TextStyle(
            color: Color(0xffeeeeee),
            fontSize: 17,
          ),
        );
  }
and in DirectionalCountryListTile

 return ListTile(
      key: Key(TestHelper.countryItemKeyValue(country.alpha2Code)),
      leading: (showFlags ? _Flag(country: country, useEmoji: useEmoji) : null),
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          '${Utils.getCountryName(country, locale)}',
          textDirection: Directionality.of(context),
          textAlign: TextAlign.start,
        ),
      ),
      subtitle: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          '${country.dialCode ?? ''}',
          textDirection: TextDirection.ltr,
          style: TextStyle(color: const Color(0xff838997)),
          textAlign: TextAlign.start,
        ),
      ),
      onTap: () => Navigator.of(context).pop(country),
    );
    