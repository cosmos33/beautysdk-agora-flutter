//
//  MMBeautyHelp.swift
//  agora_rtc_engine
//
//  Created by Zzz on 2021/10/14.
//

import Foundation
import MMBeautyKit


func getMMBeautyTypeKey(_ type: String) -> MMBeautyFilterKey {
    switch type {
    case "skin_whitening":
        return .SKIN_WHITENING
    case "skin_smooth":
        return .SKIN_SMOOTH
    case "sharpen":
        return .SHARPEN
    case "big_eye":
        return .BIG_EYE
    case "thin_face":
        return .THIN_FACE
    case "ruddy":
        return .RUDDY
    case "jaw_shape":
        return .JAW_SHAPE
    case "face_width":
        return .FACE_WIDTH
    case "chin_length":
        return .CHIN_LENGTH
    case "forehead":
        return .FOREHEAD
    case "shorten_face":
        return .SHORTEN_FACE
    case "eye_tilt":
        return .EYE_TILT
    case "eye_distance":
        return .EYE_DISTANCE
    case "nose_lift":
        return .NOSE_LIFT
    case "nose_size":
        return .NOSE_SIZE
    case "nose_width":
        return .NOSE_WIDTH
    case "nose_ridge_width":
        return .NOSE_RIDGE_WIDTH
    case "nose_tip_size":
        return .NOSE_TIP_SIZE
    case "lip_thickness":
        return .LIP_THICKNESS
    case "mouth_size":
        return .MOUTH_SIZE
    case "nasolabial_folds":
        return .NASOLABIALFOLDSAREA
    case "eye_height":
        return .EYE_HEIGHT
    case "eye_bright":
        return .EYEBRIGHTEN
    case "skin_smoothing_eyes":
        return .EYESAREA
    case "cheekbone_width":
        return .CHEEKBONE_WIDTH
    case "jaw_width":
        return .JAW2_WIDTH
    case "teeth_white":
        return .TEETHWHITEN
    case "blush":
        return .BLUSH
    case "eyebrow":
        return .EYEBROW
    case "eyeshadow":
        return .EYESHADOW
    case "lip":
        return .LIP
    case "facial":
        return .FACIAL
    case "pupil":
        return .PUPIL
    case "makeupstyle":
        return .MAKEUPALL
    case "makeuplut":
        return .MAKEUPLUT
    default:
        return .SKIN_WHITENING
    }
}

func getMMAutoBeautyType(_ type:String) -> MMBeautyAutoType {
    switch type {
    case "null":
        return .type_Normal
    case "natural":
        return .type_Natural
    case "cute":
        return .type_Lovely
    case "goddess":
        return .type_Goddess
    case "purewhite":
        return .type_Whitening
    default:
        return .type_Normal
    }
}
