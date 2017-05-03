#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr 26 15:06:12 2017

@author: leoara01
Examples:
drive_on_game.py --ip=10.45.65.58
"""
import argparse
import game_communication
import tensorflow as tf
import scipy.misc
import model
import time

# Force to see just the first GPU
# https://devblogs.nvidia.com/parallelforall/cuda-pro-tip-control-gpu-visibility-cuda_visible_devices/
import os

class GameRecord:
    __m_id = 0
    __m_img = 0
    __m_telemetry = []

    def __init__(self, id_record, img, telemetry):
        self.__m_id = id_record
        self.__m_img = img
        self.__m_telemetry = telemetry

    def get_id(self):
        return self.__m_id

    def get_image(self):
        return self.__m_img

    def get_telemetry(self):
        return self.__m_telemetry


# Parser command arguments
# Reference:
# https://www.youtube.com/watch?v=cdblJqEUDNo
parser = argparse.ArgumentParser(description='Drive inside game')
parser.add_argument('--ip', type=str, required=False, default='127.0.0.1', help='Server IP address')
parser.add_argument('--port', type=int, required=False, default=50007, help='Server TCP/IP port')
parser.add_argument('--model', type=str, required=False, default='save/model.ckpt', help='Trained driver model')
parser.add_argument('--gpu', type=int, required=False, default=0, help='GPU number (-1) for CPU')
args = parser.parse_args()


def game_pilot(ip, port, model_path, gpu):

    # Set enviroment variable to set the GPU to use
    if gpu != -1:
        os.environ["CUDA_VISIBLE_DEVICES"] = str(gpu)
    else:
        print('Set tensorflow on CPU')
        os.environ["CUDA_VISIBLE_DEVICES"] = ""

    # Load tensorflow model
    print("Loading model: %s" % model_path)
    sess = tf.InteractiveSession()
    saver = tf.train.Saver()
    saver.restore(sess, model_path)

    print(ip)
    print(port)

    comm = game_communication.GameTelemetry(ip, port)
    comm.connect()

    # Run until Crtl-C
    try:
        list_records = []
        while True:
            # Get telemetry and image
            telemetry = comm.get_game_data()
            cam_img = comm.get_image()

            # Skip entire record if image is invalid
            if (cam_img is None) or (telemetry is None):
                continue

            # Sleep for 50ms
            time.sleep(0.05)

            # Resize image to the format expected by the model
            cam_img_res = scipy.misc.imresize(cam_img, [66, 200]) / 255.0

            # Get steering angle from tensorflow model (Also convert from rad to degree)
            degrees = model.y.eval(feed_dict={model.x: [cam_img_res]})[0][0]
            print(degrees)

            # Send command to game here...
            commands = [degrees, 0.5]
            comm.send_command(commands)

    except KeyboardInterrupt:
        pass

    # Python main


if __name__ == "__main__":
    # Call function that implement the auto-pilot
    game_pilot(args.ip, args.port, args.model, args.gpu)