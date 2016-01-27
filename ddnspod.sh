
#!/bin/sh

#################################################
# AnripDdns v6.0
# 基于DNSPod用户API实现的动态域名客户端
# 作者: 若海[mail@anrip.com]
# 介绍: http://www.anrip.com/ddnspod
#	6.0修改者:MonserYuan, email: yuan@monsteryuan.com
# 6.0为了用在小米路由上,增加了循环,每15分钟检测一次,
# 如IP有变化就更新, 把原有email&pass验证更新为最新
# 的Token验证,详情https://support.dnspod.cn/Kb/showarticle/tsid/227/
# 时间: 2016-01-27 15:25:00
#################################################

# 全局变量表
arToken=""

# 获得外网地址
arIpAdress() {
    local inter="http://members.3322.org/dyndns/getip"
    wget --quiet --output-document=- $inter
}

# 查询域名地址
# 参数: 待查询域名
arNslookup() {
    local inter="http://119.29.29.29/d?dn="
    wget --quiet --output-document=- $inter$1
}

# 读取接口数据
# 参数: 接口类型 待提交数据
arApiPost() {
    local agent="AnripDdns_yuan/5.08(yuan@monsteryuan.com)"
    local inter="https://dnsapi.cn/${1:?'Info.Version'}"
    local param="login_token=${arToken}&format=json&${2}"
    wget --quiet --no-check-certificate --output-document=- --user-agent=$agent --post-data $param $inter
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
    local domainID recordID recordRS recordCD
    # 获得域名ID
    domainID=$(arApiPost "Domain.Info" "domain=${1}")
    domainID=$(echo $domainID | sed 's/.\+{"id":"\([0-9]\+\)".\+/\1/')
    # 获得记录ID
    recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
    recordID=$(echo $recordID | sed 's/.\+\[{"id":"\([0-9]\+\)".\+/\1/')
    # 更新记录IP
    recordRS=$(arApiPost "Record.Ddns" "domain_id=${domainID}&record_id=${recordID}&sub_domain=${2}&record_line=默认")
    recordCD=$(echo $recordRS | sed 's/.\+{"code":"\([0-9]\+\)".\+/\1/')
    # 输出记录IP
    if [ "$recordCD" == "1" ]; then
        echo $recordRS | sed 's/.\+,"value":"\([0-9\.]\+\)".\+/\1/'
        return 1
    fi
    # 输出错误信息
    echo $recordRS | sed 's/.\+,"message":"\([^"]\+\)".\+/\1/'
}

# 动态检查更新
# 参数: 主域名 子域名
arDdnsCheck() {
    local postRS
    local hostIP=$(arIpAdress)
    local lastIP=$(arNslookup "${2}.${1}")
    echo "hostIP: ${hostIP}"
    echo "lastIP: ${lastIP}"
    if [ "$lastIP" != "$hostIP" ]; then
        postRS=$(arDdnsUpdate $1 $2)
        echo "postRS: ${postRS}"
        if [ $? -ne 1 ]; then
            return 0
        fi
    fi
    return 1
}

###################################################

# 设置用户参数 设为"ID,Token"
arToken="id,token"

# 检查更新域名 sleep可改 单位为分钟
while [ 1 ];do
				arDdnsCheck "anrip.com" "lab"
				sleep 900
done
