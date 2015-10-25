# do_ss
A auto deploy  ss to digital ocean vps.

# 使用说明

你需要准备一台DO的VPS
假定你使用的Mac OSX，如果是Linux，请自行替换shadowsocks-local为Linux的版本，这里是go版本的。

部署一个SSH的key到服务器上。

获得API的Token

执行
```bash
curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer b7d03a6947b217efb6f3ec3bd3504582' "https://api.digitalocean.com/v2/account/keys"

```

获得SSH Key的Id

修改droplet.rb文件

```ruby

ACCESS_TOKEN = "399bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # 更改为你的Access_token.
SSH_KEY_ID = 1203333 # 查你的SSH Key 的ID，执行curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer b7d03a6947b217efb6f3ec3bd3504582' "https://api.digitalocean.com/v2/account/keys"

```

将ACCESS_TOKEN和SSH_KEY_ID的指替换成你自己的值。


#部署

执行

```bash
mina setup

```
部署完成后执行

```bash
./shadowsocks-local -c config.json
```

删除

```bash
mina drop
```
