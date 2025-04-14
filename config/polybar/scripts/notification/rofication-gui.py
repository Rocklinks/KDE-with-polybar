#!/usr/bin/env python3
import sys
import re
import socket
import struct
import subprocess
import jsonpickle
from gi.repository import GLib
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk
from enum import Enum
from msg import Msg,Urgency
import shutil

def get_dynamic_lines(num_notifications, font_height=20, max_screen_ratio=0.4):
    screen_height = shutil.get_terminal_size().lines * font_height
    
    # Calculate the maximum height based on the screen ratio (40% of screen height)
    max_window_height = int(screen_height * max_screen_ratio)
    
    # Calculate the maximum number of lines that can fit into this window
    max_lines = max_window_height // font_height
    
    # Return the lesser of the number of notifications or the calculated max lines
    return min(num_notifications, max_lines)


def linesplit(socket):
    buffer = socket.recv(16)
    buffer = buffer.decode("UTF-8")
    buffering = True
    while buffering:
        if '\n' in buffer:
            (line, buffer) = buffer.split("\n", 1)
            yield line
        else:
            more = socket.recv(16)
            more = more.decode("UTF-8")
            if not more:
                buffering = False
            else:
                buffer += more
    if buffer:
        yield buffer

msg = """<span font-size='small'><i>Alt+s</i>:Dismiss                <i>Alt+a</i>:Delete</span>""";
rofi_command = [ 'rofi' , '-dmenu', '-p', 'Notifications:', '-markup', '-mesg', msg, '-theme', '~/.config/polybar/rofi/catppuccin-lavrent.rasi', '-location', '2', '-yoffset', '28']

def strip_tags(value):
  "Return the given HTML with all tags stripped."
  return re.sub(r'<[^>]*?>', '', value)

def call_rofi(entries, additional_args=[]):
    dynamic_lines = get_dynamic_lines(len(entries))
    additional_args.extend([ '-kb-custom-1', 'Alt+s',
                             '-kb-custom-4', 'Alt+a',
                             '-markup-rows',
                             '-sep', '\3',
                             '-format', 'i',
                             '-columns', '3',
                             '-lines', str(dynamic_lines),
                             '-eh', '2',
                             '-width', '-70', ])
    proc = subprocess.Popen(rofi_command+ additional_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    for e in entries:
        proc.stdin.write((e).encode('utf-8'))
        proc.stdin.write(struct.pack('B', 3))
    proc.stdin.close()
    answer = proc.stdout.read().decode("utf-8")
    exit_code = proc.wait()
    # trim whitespace
    if answer == '':
        return None,exit_code
    else:
        return int(answer),exit_code


def send_command(cmd):
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect("/tmp/rofi_notification_daemon")
    print("Send: {cmd}".format(cmd=cmd))
    client.send(bytes(cmd, 'utf-8'))
    client.close()


did = None
cont=True
while cont:
    cont=False
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect("/tmp/rofi_notification_daemon")
    client.send(b"list",4)
    ids=[]
    entries=[]
    index=0
    urgent=[]
    low=[]
    args=[]
    from collections import defaultdict

    grouped_msgs = defaultdict(list)
    for a in linesplit(client):
        if len(a) > 0:
            msg = jsonpickle.decode(a)
            grouped_msgs[msg.application].append(msg)

    ids = []
    entries = []
    index = 0
    urgent = []
    low = []

    for app, messages in grouped_msgs.items():
        notif_count = len(messages)
        title = GLib.markup_escape_text(strip_tags(messages[0].summary))
        app_name = GLib.markup_escape_text(strip_tags(app))
        if notif_count > 1:
            title += f" ({notif_count}×)"

        combined_summary = f"<b>{title}</b> <small>({app_name})</small>"
     
        combined_body = "\n".join([
            "- " + GLib.markup_escape_text(strip_tags(m.body.replace("\n", " ")))
            for m in messages if m.body
        ])
        if combined_body:
            combined_summary += "\n<i>{}</i>".format(combined_body)

        if messages[0].app_icon:
            combined_summary += "\0icon\x1f{}".format(messages[0].app_icon)

        entries.append(combined_summary)
        ids.append(messages[0])  # You can store the first message for actions
        urgency = Urgency(messages[0].urgency)
        if urgency is Urgency.critical:
            urgent.append(str(index))
        elif urgency is Urgency.low:
            low.append(str(index))
        index += 1
    # Show rofi
    dynamic_lines = get_dynamic_lines(len(entries))
    args.extend(["-lines", str(dynamic_lines)])
    did, code = call_rofi(entries, args)
    print("{a},{b}".format(a=did,b=code))
    # Dismiss notification
    if did != None and code == 10:
        send_command("del:{mid}".format(mid=ids[did].mid))
        cont=True
    # Seen notification
    elif did != None and code == 11:
        send_command("saw:{mid}".format(mid=ids[did].mid))
        cont=True
    elif did != None and code == 12:
        cont=True
    elif did != None and code == 13:
        send_command("dela:{app}".format(app=ids[did].application))
        cont=True


with open('/tmp/notification_count', 'w') as f:
    f.write('1')


import os
os.remove('/tmp/notification_count') 

