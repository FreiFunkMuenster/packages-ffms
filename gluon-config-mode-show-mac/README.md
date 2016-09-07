gluon-config-mode-show-mac
============

Zeigt auf der Reboot Page die Primäre MAC-Adresse und den Knotennamen an. 

Folgendes muss dazu in die de.po eingetragen werden.
'' msgid "gluon-config-mode:macaddr" ''
'' msgstr "" ''
'' "Dies ist die Primäre MAC-Adresse deines Freifunkknotens: <em><%=macaddr%></em>. Erst nachdem er auf den Servern des Münsterländer Freifunk-Projektes eingetragen wurde, kann sich dein Knoten mit dem Münsterländer Mesh-VPN verbinden. Bitte schicke dazu diesen Schlüssel und den Namen deines Knotens (<em><%=hostname%></em>) an <a href='mailto:info@freifunk-muenster.de?subject=Neuer%20Freifunkknoten&body=%23%20<%=hostname%>%0amacaddr%20%22<%=macaddr%>%22%3b'>info@freifunk-muensterland.de</a>." ''