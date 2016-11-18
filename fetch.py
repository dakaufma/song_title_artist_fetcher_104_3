#!/usr/bin/python3

from bs4 import BeautifulSoup
import urllib.request
import sys

url = 'http://1043myfm.iheart.com/playlist/'
html = urllib.request.urlopen(url).read()
soup = BeautifulSoup(html, "lxml")

playlist_ols = soup.find_all('ol', 'playlist-items')
if len(playlist_ols) != 1:
    print("Bad playlist length " + len(paylist_ols))
    print(soup.prettify())
    sys.exit(1)
playlist_ol = playlist_ols[0]

playlist_lis = playlist_ol.find_all('li')
songs = [] # (title, artist)
for li in playlist_lis:
    try:
        title = li.find_all('h3')[0].text
        artist = li.find_all('a', {'class':'track-artist'})[0].text
        songs.append((title, artist))
    except:
        print("Failed to extract title or artist from playlist entry")
        print(li.prettify())
        print()
print(songs)

