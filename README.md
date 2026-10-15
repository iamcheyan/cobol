# GnuCOBOL 实战课程

**从第一条 COBOL 语句，走到可运行的银行夜间对账系统。**

仓库首页就是课程入口。32 课循序渐进，覆盖 COBOL 基础、数据布局、文件处理、排序突合、数据库和模块化批处理，最终完成银行夜间对账毕业项目。

## 开始上课

1. 安装 GnuCOBOL 与 Make：
   ```sh
   sudo apt install gnucobol make
   cobc --version
   ```
2. 从[第 01 课](lessons/01_hello-cobol/README.md)开始；每课都有讲解、源码、练习和参考答案。
3. 打开[课程总目录](lessons/DIRECTORY.md)查看 32 课的顺序、目标和预计时间。

检查全部 32 课的交付物、对第 01–28 课做语法检查并编译运行第 01 课：

```sh
make course-check
```

第 29–32 课使用 GixSQL + SQLite 工具链（先在第 29 课运行 `install-toolchain.sh`），用下面的目标覆盖预编译检查与第 32 课端到端场景：

```sh
make course-check-sql
```

## 课程结构

- [`lessons/`](lessons/README.md)：32 课主课程。第 32 课是可运行的银行对账毕业项目。
- [`extensions/`](extensions/README.md)：非必修内容，包括旧版课程、企业进阶模块、独立示例和 Neovim 插件教程。
- [`Makefile`](Makefile)：主课程检查，以及可选扩展的独立示例检查与运行入口。

先完成 32 课主线即可完成课程；扩展内容不会改变主课顺序或先修要求。
