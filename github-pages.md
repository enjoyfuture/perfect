创建 github pages

# 利用 git subtree 提交代码到 GitHub Pages 

利用 git subtree 可以很方便的管理 gh-pages 分支

以下命令列出了详细操作，初始化的时候需要先执行前两步，再执行第三步，以后更新 gh-pages 时，只需执行第三步即可。

1. 创建 gh-pages 分支，**注意：在执行 git subtree add 命令之前，需确保 gh-pages 分支下至少存在一个文件**
```
git checkout -b gh-pages //创建并切换到分支 gh-pages
rm -rf *  //隐藏文件需要单独删除，结合命令 ls -a
git add -A
git commit -m "clear gh-page"
vim .gitignore
git add .gitignore //输入要忽略的文件
git commit -m ".gitignore"
git push --set-upstream origin gh-pages
git checkout master
```

2. 把分支 gh-pages 添加到本地 subtree 中，执行该命令前，请确保 _gh_pages 文件夹不存在

```
git subtree add --prefix=_gh_pages origin gh-pages --squash
```
  
3. 生成 docs
```
gulp build-doc
git add -A _gh_pages
git commit -m "Update docs"
# git subtree pull --prefix=_gh_pages git@github.com:enjoyfuture/perfect.git gh-pages --squash
git subtree push --prefix=_gh_pages origin gh-pages --squash
git push
```

# 绑定域名

1. Ping enjoyfuture.github.io 拿到 enjoyfuture.github.io 对应的 ip
2. 在注册域名服务商，添加 DNS 解析（已万网阿里云为例）
   记录类型 	主机记录 	解析线路(运营商) 	   记录值	
  	  A	     www	        默认	        1中拿到的对应 ip，不需要设置端口 访问 www.perfect-css.com
  	  A	      @	          默认	        1中拿到的对应 ip，不需要设置端口 可以直接访问 perfect-css.com
3. 绑定域名 perfect-css.com
   在 https://github.com/enjoyfuture/perfect/settings 中，找到 `Custom domain` 处，输入
   perfect-css.com 点击 save 即可。该操作，相当于在 gh-pages 分支中新建 CNAME 文件，并添加 perfect-css.com
