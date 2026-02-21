#!/bin/bash

rm -rf feeds/packages/lang/golang
git clone --filter=blob:none --depth 1 --single-branch https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
git clone --filter=blob:none --depth 1 --single-branch https://github.com/pymumu/openwrt-smartdns -b master package/custom/smartdns
git clone --filter=blob:none --depth 1 --single-branch https://github.com/pymumu/luci-app-smartdns -b master package/custom/luci-app-smartdns
git clone --filter=blob:none --depth 1 --single-branch https://github.com/Openwrt-Passwall/openwrt-passwall -b main package/custom/openwrt-passwall
git clone --filter=blob:none --depth 1 --single-branch https://github.com/Openwrt-Passwall/openwrt-passwall-packages -b main package/custom/passwall-packages
git clone --filter=blob:none --depth 1 --single-branch https://github.com/tty228/luci-app-wechatpush -b master package/custom/luci-app-wechatpush
git clone --filter=blob:none --depth 1 --single-branch https://github.com/hubbylei/wrtbwmon -b master package/custom/wrtbwmon
git clone --filter=blob:none --depth 1 --single-branch https://github.com/hubbylei/openwrt-cdnspeedtest -b master package/custom/openwrt-cdnspeedtest
git clone --filter=blob:none --depth 1 --single-branch https://github.com/hubbylei/luci-app-cloudflarespeedtest -b main package/custom/luci-app-cloudflarespeedtest
git clone --filter=blob:none --depth 1 --single-branch https://github.com/hubbylei/luci-theme-bootstrap-mod -b main package/custom/luci-theme-bootstrap-mod

cp -rf package/custom/openwrt-passwall/luci-app-passwall package/custom/
rm -rf package/custom/passwall-packages/.git*
cp -rf package/custom/passwall-packages/* package/custom/
cp -rf package/custom/openwrt-cdnspeedtest/cdnspeedtest package/custom/
rm -rf package/custom/openwrt-passwall
rm -rf package/custom/passwall-packages
rm -rf package/custom/openwrt-cdnspeedtest

del_data=$(ls package/custom)
for data in ${del_data}
do
    isdel=$(find feeds -iname "${data}")
    if [[ -n ${isdel} && -d ${isdel} ]];then
        rm -rf ${isdel}
        echo "Deleted ${isdel}"
    fi
done

sed -i '/sed -r -i/a\\tsed -i "s,#Port 22,Port 22,g" $(1)\/etc\/ssh\/sshd_config\n\tsed -i "s,#ListenAddress 0.0.0.0,ListenAddress 0.0.0.0,g" $(1)\/etc\/ssh\/sshd_config\n\tsed -i "s,#PermitRootLogin prohibit-password,PermitRootLogin yes,g" $(1)\/etc\/ssh\/sshd_config' feeds/packages/net/openssh/Makefile
sed -i 's/;Listen = 0.0.0.0:1688/Listen = 0.0.0.0:1688/g' feeds/packages/net/vlmcsd/files/vlmcsd.ini

GEOIP_VER=$(echo -n `curl -sL -H "${AUTH}" https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | jq -r .tag_name`)
GEOIP_HASH=$(echo -n `curl -sL -H "${AUTH}" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${GEOIP_VER}/geoip.dat.sha256sum | awk '{print $1}'`)
GEOSITE_VER=${GEOIP_VER}
GEOSITE_HASH=$(echo -n `curl -sL -H "${AUTH}" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${GEOSITE_VER}/geosite.dat.sha256sum | awk '{print $1}'`)
sed -i '/HASH:=/d' package/custom/v2ray-geodata/Makefile
sed -i 's/Loyalsoldier\/geoip/Loyalsoldier\/v2ray-rules-dat/g' package/custom/v2ray-geodata/Makefile
sed -i 's/GEOIP_VER:=.*/GEOIP_VER:='"${GEOIP_VER}"'/g' package/custom/v2ray-geodata/Makefile
sed -i '/FILE:=$(GEOIP_FILE)/a\ HASH:='"${GEOIP_HASH}"'' package/custom/v2ray-geodata/Makefile
sed -i 's/GEOSITE_VER:=.*/GEOSITE_VER:='"${GEOSITE_VER}"'/g' package/custom/v2ray-geodata/Makefile
sed -i '/FILE:=$(GEOSITE_FILE)/a\ HASH:='"${GEOSITE_HASH}"'' package/custom/v2ray-geodata/Makefile
sed -i 's/URL:=https:\/\/www.v2fly.org/URL:=https:\/\/github.com\/Loyalsoldier\/v2ray-rules-dat/g' package/custom/v2ray-geodata/Makefile

SMARTDNS_JSON=$(curl -sL -H "${AUTH}" https://api.github.com/repos/pymumu/smartdns/commits | jq .[0])
SMARTDNS_VER=$(echo -n `echo ${SMARTDNS_JSON} | jq -r .commit.committer.date | awk -F "T" '{print $1}' | sed 's/\-/\./g'`)
SMARTDNS_SHA=$(echo -n `echo ${SMARTDNS_JSON} | jq -r .sha`)
sed -i '/PKG_MIRROR_HASH:=/d' package/custom/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"${SMARTDNS_VER}"'/g' package/custom/smartdns/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"${SMARTDNS_SHA}"'/g' package/custom/smartdns/Makefile
sed -i 's/..\/..\/lang\/rust\/rust-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/rust\/rust-package.mk/g' package/custom/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"${SMARTDNS_VER}"'/g' package/custom/luci-app-smartdns/Makefile
sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' package/custom/luci-app-smartdns/Makefile

curl -sL -o /tmp/frp-0.66.0.tar.gz https://codeload.github.com/fatedier/frp/tar.gz/v0.66.0?
FRP_PKG_SHA=$(sha256sum /tmp/frp-0.66.0.tar.gz | awk '{print $1}')
rm -rf /tmp/frp-0.66.0.tar.gz
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=0.66.0/g' feeds/packages/net/frp/Makefile
sed -i 's/PKG_HASH:=.*/PKG_HASH:='${FRP_PKG_SHA}'/g' feeds/packages/net/frp/Makefile
sed -i 's/\$(2)_full.ini/legacy\/\$(2)_legacy_full.ini/g' feeds/packages/net/frp/Makefile
