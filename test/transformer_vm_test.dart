// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
library scissors.test;

import 'package:barback/barback.dart';
import 'package:scissors/transformer.dart';
import 'package:scissors/src/async_transformer_test_utils.dart';

final phases = [
  [
    new ScissorsTransformer.asPlugin(
        new BarbackSettings({}, BarbackMode.RELEASE))
  ]
];

void main() {
  testPhasesAsync('leaves css based on angular2 annotations without css url alone', phases, {
    'a|foo2_unmatched_css_url.css': r'''
      .used-class {}
      .unused-class {}
      absent-element {}
      present-element {}
    ''',
    'a|foo2_unmatched_css_url.dart': r'''
      import 'package:angular2/angular2.dart';

      @Component(selector = 'foo2_unmatched_css_url')
      @View(template = '<present-element></present-element>',
          styleUrls = const ['package:a/something_else.css'])
      class FooComponent {}

      @Component(selector = 'bar')
      @View(template = '<div class="used-class inexistent-class"></div>')
      class BarComponent {}
    ''',
  }, {
    'a|foo2_unmatched_css_url.css': r'''
      .used-class {}
      .unused-class {}
      absent-element {}
      present-element {}
    '''
  });
  testPhasesAsync('does basic class and element selector pruning', phases, {
    'a|foo2_html.css': r'''
      .used-class {}
      .unused-class {}
      absent-element {}
      present-element {}
    ''',
    'a|foo2_html.html': r'''
      <present-element class="used-class inexistent-class">
      </present-element>
    ''',
  }, {
    'a|foo2_html.css': r'''
      .used-class {}
      present-element {}
    '''
  });
  testPhasesAsync('prunes css based on angular2 annotations in .dart companion', phases, {
    'a|foo2_dart.css': r'''
      .used-class {}
      .unused-class {}
      absent-element {}
      present-element {}
    ''',
    'a|foo2_dart.dart': r'''
      import 'package:angular2/angular2.dart';

      @Component(selector = 'foo')
      @View(template = '<present-element></present-element>',
          styleUrls = const ['package:a/foo2_dart.css'])
      class FooComponent {}

      @Component(selector = 'bar')
      @View(template = '<div class="used-class inexistent-class"></div>',
          styleUrls = const ['package:a/foo2_dart.css'])
      class BarComponent {}
    ''',
  }, {
    'a|foo2_dart.css': r'''
      .used-class {}
      present-element {}
    '''
  });
  testPhasesAsync('prunes css based on angular1 annotations in .dart companion', phases, {
    'a|foo1.css': r'''
      absent-element {}
      present-element {}
    ''',
    'a|foo1.dart': r'''
      import 'package:angular/angular.dart';
      @Component(
        selector = 'foo',
        template = '<present-element></present-element>',
        cssUrl = 'package:a/foo1.css')
      class FooComponent {}
    ''',
  }, {
    'a|foo1.css': r'''
      present-element {}
    '''
  });

  testPhasesAsync('only prunes css which html it could resolve', phases, {
    'a|foo.css': r'.some-class {}',
    'a|bar.css': r'.some-class {}',
    'a|baz.scss.css': r'.some-class {}',
    'a|foo.html': r'<div></div>',
    'a|baz.html': r'<div></div>',
  }, {
    'a|foo.css': r'',
    'a|bar.css': r'.some-class {}',
    'a|baz.scss.css': r'',
  });

  testPhasesAsync('supports descending and attribute selectors', phases, {
    'a|foo.css': r'''
      html body input[type="submit"] {}
      html body input[type="checkbox"] {}
    ''',
    'a|foo.html': r'''
      <input type="submit">
    ''',
  }, {
    'a|foo.css': r'''
      html body input[type="submit"] {}
    ''',
  });

  testPhasesAsync('processes class attributes with mustaches', phases, {
    'a|foo.css': r'''
      .what_1 {}
      .what-2 {}
      .what-3 {}
      .pre1-mid-suff1 {}
      .pre1--suff1 {}
      .pre1-suff_ {}
      .pre_-suff1 {}
      .pre2-suff_ {}
      .pre_-suff2 {}
    ''',
    'a|foo.html': r'''
      <div class="what_1 pre1-{{whatever}}-suff1 pre2{{...}}
                  {{...}}suff2 what-3"></div>
    ''',
  }, {
    'a|foo.css': r'''
      .what_1 {}
      .what-3 {}
      .pre1-mid-suff1 {}
      .pre1--suff1 {}
      .pre2-suff_ {}
      .pre_-suff2 {}
    ''',
  });

  testPhasesAsync('uses constant class names from ng-class', phases, {
    'a|foo.css': r'''
      .used-class {}
      .unused-class {}
      absent-element {}
      present-element {}
    ''',
    'a|foo.html': r'''
      <present-element ng-class="{
        'used-class': ifOnly,
        'inexistent-class': notAChance
      }">
      </present-element>
    ''',
  }, {
    'a|foo.css': r'''
      .used-class {}
      present-element {}
    '''
  });

  final htmlBodyDiv = r'''
      html{font-family:sans-serif}
      body{font-family:sans-serif}
      div{font-family:sans-serif}
    ''';
  testPhasesAsync('deals with synthetic html and body', phases, {
    'a|html.css': htmlBodyDiv,
    'a|html.html': r'<html></html>',
    'a|body.css': htmlBodyDiv,
    'a|body.html': r'<body></body>',
    'a|div.css': htmlBodyDiv,
    'a|div.html': r'<div></div>',
  }, {
    'a|html.css': r'''
      html{font-family:sans-serif}
      body{font-family:sans-serif}
    ''',
    'a|body.css': r'''
      body{font-family:sans-serif}
    ''',
    'a|div.css': r'''
      div{font-family:sans-serif}
    '''
  });
}