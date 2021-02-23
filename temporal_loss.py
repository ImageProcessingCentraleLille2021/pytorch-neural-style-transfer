import cv2
import numpy as np


# input is numpy image array
def optical_flow(img, prev_img):
    next = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    prvs = cv2.cvtColor(prev_img, cv2.COLOR_RGB2GRAY)
    hsv = np.zeros_like(prev_img)
    hsv[..., 1] = 255

    flow = cv2.calcOpticalFlowFarneback(prvs, next, None, 0.5, 3, 15, 3, 5, 1.2, 0)

    mag, ang = cv2.cartToPolar(flow[...,0], flow[...,1])
    hsv[...,0] = ang*180/np.pi/2
    hsv[...,2] = cv2.normalize(mag,None,0,255,cv2.NORM_MINMAX)
    rgb = cv2.cvtColor(hsv,cv2.COLOR_HSV2RGB)
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)

    mask = np.where(gray > 0.5, 0, 1)
    gray[mask]

    return rgb, mask

def compute_temporal_loss(img, prev_img):
    opt_flow, mask = optical_flow(img, prev_img)
    gray_three = cv2.merge([mask,mask,mask])   
    return np.mean(gray_three*(img-prev_img)**2)


if __name__ == "__main__":
    img = cv2.imread('./data/content-images/lion.jpg')
    print(compute_temporal_loss(img,img))
