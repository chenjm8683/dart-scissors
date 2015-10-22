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
library scissors.name_fragment.test;

import 'package:scissors/src/name_fragment.dart';
import "package:test/test.dart";

main() {
  regexp(String pattern) => new RegExp(pattern, multiLine: true);

  test('parseClassAndClassFragments', () {
    expect(parseClassPatterns("a"), ["a"]);
    expect(parseClassPatterns("{{}}"), [regexp(r'^.*?$')]);
    expect(parseClassPatterns("{{...}}"), [regexp(r'^.*?$')]);
    expect(parseClassPatterns("a-{{b}}c_{{d}}{{e}}f g{{h}} i"), [
      regexp(r'^a-.*?c_.*?f$'),
      regexp(r'^g.*?$'),
      "i"
    ]);
    expect(parseClassPatterns("foo a{{b}}"), ["foo", regexp(r'^a.*?$')]);
    expect(parseClassPatterns("{{a}}b"), [regexp(r'^.*?b$')]);
  });
}