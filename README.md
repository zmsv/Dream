# 简介
基于闭源AstralDice的Lua框架
## AstralDice是什么？
AstralDice是某人开发的一个可供trpg跑团骰点的骰系，并且提供了**回雪**，**JavaScript**，**Lua**语言进行扩展功能的开发
## Dream的优点
 - 快速载入Lua脚本，并且迅速生成配置文件
 - 高效快捷，实现功能只需几行
 - 提供了报错处理，让报错**不再静默**
 - 通过Termux，提供了lua与其他语言交互(如PHP)的可能
## 为什么选择Dream
咱就不硬吹Dream了，~~爱用用不用滚~~
**事实也确实如此，Dream只是AstralDice的一个很小的插件**，我不希望他能声明远扬，但也希望Dream能被更多人需要
# 搭建方法
请确保你**已经安装AstralDice**，否则，请于**联系我们**目录下，找寻**AstralDiceQQ群**，加入其中，获取**群文件**中的AstralDice
## 开始搭建
  - Github上的实在懒得更，请前往DreamQQ群，进入群文件界面，找到Dream最新版~~(有时候雨岚可能会推一推新版，但是，毕竟鸽子仙人)~~
  - 解压
  - 将`dream.lua`放入`custom/data/dream/`目录下，没有则新建
  - `plugin`和`lib`文件夹也放入上述目录
  - **.system load**重载骰子或重启
### 文件目录细分
你的**custom/data/dream**文件夹下应当有以下几个文件或文件夹
  - `config`  配置文件文件夹
  - `data`    Dream的数据文件夹
  - `lib`     依赖填写**all**时默认导入的依赖
  - `plugin` 插件文件夹
  - `dream.lua` Dream框架主体
  - `sh.sh`    dream.execute函数被调动时创造的文件
# 联系我们
## AstralDiceQQ群
**731106397**
**245525828**
## AstralDice论坛
[点击这里](https://astral.snoweven.com/)
## DreamQQ群
**243093229**
