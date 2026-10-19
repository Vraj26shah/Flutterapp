import 'dart:convert';
import 'dart:io';

/// Reads a JSON fixture captured from the real DummyJSON API.
dynamic fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

Map<String, dynamic> fixtureMap(String name) =>
    fixture(name) as Map<String, dynamic>;
