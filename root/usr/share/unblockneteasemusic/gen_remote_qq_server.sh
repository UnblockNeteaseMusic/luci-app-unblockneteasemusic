#!/bin/bash
# Created By [CTCGFW]Project OpenWRT
# https://github.com/project-openwrt

[ "$1" == "1" ] && { flac_quality="'flac', "; loop_times="4"; } || loop_times="3"

echo -e "const cache = require('../cache')
const insure = require('./insure')
const select = require('./select')
const request = require('../request')

const headers = {
	'origin': 'http://y.qq.com/',
	'referer': 'http://y.qq.com/',
	'cookie': null
}

const playable = song => {
	const switchFlag = song['switch'].toString(2).split('')
	switchFlag.pop()
	switchFlag.reverse()
	const playFlag = switchFlag[0]
	const tryFlag = switchFlag[13]
	return ((playFlag == 1) || ((playFlag == 1) && (tryFlag == 1)))
}

const format = song => ({
	id: {song: song.mid, file: song.file.media_mid},
	name: song.name,
	duration: song.interval * 1000,
	album: {id: song.album.mid, name: song.album.name},
	artists: song.singer.map(({mid, name}) => ({id: mid, name}))
})

const search = info => {
	const url =
		'https://c.y.qq.com/soso/fcgi-bin/client_search_cp?' +
		'ct=24&qqmusic_ver=1298&new_json=1&remoteplace=txt.yqq.center&' +
		't=0&aggr=1&cr=1&catZhida=1&lossless=0&flag_qc=0&p=1&n=20&w=' +
		encodeURIComponent(info.keyword) + '&' +
		'g_tk=5381&jsonpCallback=MusicJsonCallback10005317669353331&loginUin=0&hostUin=0&' +
		'format=jsonp&inCharset=utf8&outCharset=utf-8&notice=0&platform=yqq&needNewCode=0'

	return request('GET', url)
	.then(response => response.jsonp())
	.then(jsonBody => {
		const list = jsonBody.data.song.list.map(format)
		const matched = select(list, info)
		return matched ? matched.id : Promise.reject()
	})
}

const track = id => {
	const typeObj = [${flac_quality}'320', '128', 'm4a']

	let i = 0
	while (i < ${loop_times}) {
		type = typeObj[i]
		let url =
			'https://api.qq.jsososo.com/song/url?id=' +
			id.song + '&mediaId=' + id.file + '&type=' + \`\${type}\`

		return request('GET', url)
		.then(response => response.json())
		.then(jsonBody => {
			let res = jsonBody.result
			if (res === 100) {
				let songUrl = jsonBody.data
				return songUrl
			} else if (i === 3) {
				return Promise.reject()
			} else {
				return
			}
		})
		.catch(() => insure().qq.track(id))
		i++
	}
}

const check = info => cache(search, info).then(track)

module.exports = {check, track}"
