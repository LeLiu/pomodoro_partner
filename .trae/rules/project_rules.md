1. 尽量不要使用`flutter clean`命令；
2. 如果使用了新的package，请检查并修改`pubspec.yaml`文件；
3. 运行使用`flutter run -d windows --verbose`命令；
4. 如果程序已经在运行，请直接使用`r`或者`R`命令，不用echo；
5. 程序运行不起来先检查代码中有没有括号为对齐、变量未命名等基本问题（可扩展），并认真分析日志，避免尝试使用命令来分析；
6. 如果要使用命令分析，先使用`flutter analyze`静态分析。