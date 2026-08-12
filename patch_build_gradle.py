import sys

with open('android/build.gradle.kts', 'r') as f:
    content = f.read()

if 'allprojects {\n    afterEvaluate {\n        val androidExt' in content:
    content = content.split('allprojects {\n    afterEvaluate {\n        val androidExt')[0]

with open('android/build.gradle.kts', 'w') as f:
    f.write(content.strip() + '\n')
