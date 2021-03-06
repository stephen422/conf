-- Compiler flags --
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts #-}

-- Imports --
import XMonad

import Graphics.X11.ExtraTypes.XF86
import XMonad.Actions.CycleWS
import XMonad.Actions.SwapWorkspaces
import XMonad.Actions.WorkspaceNames
import XMonad.Actions.DynamicWorkspaces
import XMonad.Actions.CopyWindow(copy)
-- import XMonad.Actions.Navigation2D
import XMonad.Actions.GroupNavigation
import XMonad.Prompt
import XMonad.Prompt.Shell

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.InsertPosition
import XMonad.Hooks.EwmhDesktops

import XMonad.Layout
import XMonad.Layout.NoBorders as NB
import XMonad.Layout.Spacing
-- import XMonad.Layout.ResizableTile
import XMonad.Layout.Renamed
import XMonad.Layout.Fullscreen
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.SubLayouts
import XMonad.Layout.Decoration
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.PerWorkspace
import qualified XMonad.StackSet as W
import XMonad.Layout.WindowNavigation
import XMonad.Layout.BoringWindows
import XMonad.Layout.Tabbed
import XMonad.Layout.Simplest

import XMonad.Util.Run (spawnPipe, hPutStrLn)

import qualified Data.Map as M
import Control.Monad (when, join)
import Data.Maybe (maybeToList)

-- Notes.
--
-- Fullscreen issue:
-- - see https://github.com/xmonad/xmonad-contrib/issues/183#issuecomment-307407822
--
------------------------------------------------------------------------------------------
-- Main Configuration
main :: IO()
--main = xmonad =<< statusBar myBar myPP toggleStrutsKey myConfig
main = do
        h <- spawnPipe myBar
        xmonad $ ewmh $ fullscreenSupport $ docks
               -- $ navigation2D def
               --                (xK_Up, xK_Left, xK_Down, xK_Right)
               --                [(mod4Mask,               windowGo  ),
               --                (mod4Mask .|. shiftMask, windowSwap)]
               --                False
               $ myConfig h

myConfig p = def
        { workspaces = myWorkspaces
        , manageHook = myManageHook <+> manageHook defaultConfig -- merge with default
        , handleEventHook = myHandleEventHook
        , layoutHook = myLayoutHook
        , logHook = myLogHook p
        , startupHook = addEWMHFullscreen
        , modMask = mod4Mask
        , terminal = "st"
        , keys = \c -> mykeys c `M.union` keys def c
        , focusedBorderColor = foreground
        , normalBorderColor = background
        , borderWidth = 3
        }

-- myWorkspaces = ["web", "emacs", "dev","sys", "5","6","7","8","9"]
myWorkspaces = ["1","2","3","4","5","6","7","8","9"]
foreground = "#81a2be"
background = "#1d1f21"

------------------------------------------------------------------------------------------
-- Keybindings
mykeys (XConfig {modMask = modm}) = M.fromList $
        [
          ((modm,                 xK_h), sendMessage $ Go L)
        , ((modm,                 xK_l), sendMessage $ Go R)
        , ((modm,                 xK_k), sendMessage $ Go U)
        , ((modm,                 xK_j), sendMessage $ Go D)
        , ((modm .|. shiftMask,   xK_h), sendMessage $ Swap L)
        , ((modm .|. shiftMask,   xK_l), sendMessage $ Swap R)
        , ((modm .|. shiftMask,   xK_k), sendMessage $ Swap U)
        , ((modm .|. shiftMask,   xK_j), sendMessage $ Swap D)

        , ((modm .|. controlMask, xK_h), sendMessage $ pullGroup L)
        , ((modm .|. controlMask, xK_l), sendMessage $ pullGroup R)
        , ((modm .|. controlMask, xK_k), sendMessage $ pullGroup U)
        , ((modm .|. controlMask, xK_j), sendMessage $ pullGroup D)
        , ((modm .|. controlMask, xK_m), withFocused (sendMessage . MergeAll))
        , ((modm .|. controlMask, xK_u), withFocused (sendMessage . UnMerge))
        , ((modm, xK_semicolon), onGroup W.focusUp')
        , ((modm, xK_apostrophe), onGroup W.focusDown')
        , ((modm, xK_c), focusDown)
        , ((modm, xK_bracketleft), sendMessage Shrink)
        , ((modm, xK_bracketright), sendMessage Expand)

        -- fullscreen toggle
        , ((modm, xK_f), sendMessage ToggleLayout)

        , ((modm , xK_grave), nextMatchWithThis Forward  className)

        -- workspaces
        , ((modm .|. shiftMask, xK_BackSpace), removeWorkspace)
        , ((modm .|. shiftMask, xK_r), XMonad.Actions.WorkspaceNames.renameWorkspace prompt_conf)
        -- , ((modm, xK_m), withWorkspace prompt_conf (windows . W.shift))

        , ((modm, xK_w),      withFocused killWindow)
        , ((modm, xK_Tab),    toggleWS)
        , ((modm , xK_p),     spawn "rofi -modi run,drun -show run")
        , ((modm , xK_s),     spawn "screenshot")
        , ((modm, xK_b     ), sendMessage ToggleStruts)

        -- media keys
        , ((0, xF86XK_AudioRaiseVolume), spawn "amixer -q sset Master 2%+")
        , ((0, xF86XK_AudioLowerVolume), spawn "amixer -q sset Master 2%-")
        , ((0, xF86XK_AudioMute), spawn "amixer -q sset Master toggle")
        , ((0, xF86XK_AudioMicMute), spawn "amixer -q sset Capture toggle")
        , ((0, xF86XK_MonBrightnessUp), spawn "sudo oled-backlight +")
        , ((0, xF86XK_MonBrightnessDown), spawn "sudo oled-backlight -")
        ]
        ++
        [((modm .|. controlMask, k), XMonad.Actions.WorkspaceNames.swapWithCurrent i)
            | (i, k) <- zip myWorkspaces [xK_1 ..]]
        -- ++ zip (zip (repeat (modm)) [xK_1..xK_9]) (map (withNthWorkspace W.greedyView) [0..])

prompt_conf = def {
      position = Top
    , font = "xft:Hack:size=10"
    , height = 50
}

------------------------------------------------------------------------------------------
-- Constants
myBar = "xmobar /home/hansung/.xmobarrc"


------------------------------------------------------------------------------------------
-- Manage hook
myManageHook :: ManageHook
myManageHook =
        manageDocks
    <+> XMonad.Layout.Fullscreen.fullscreenManageHook
    <+> composeAll
            [ className =? "kakaotalk.exe" --> doFloat
            , className =? "Wine" --> doFloat
            , className =? "Slack" --> doShift "8"
            , isFullscreen --> doShift "8" -- FIXME
            ]


------------------------------------------------------------------------------------------
-- Handle event hook
myHandleEventHook = docksEventHook
                <+> handleEventHook def
                <+> XMonad.Layout.Fullscreen.fullscreenEventHook


------------------------------------------------------------------------------------------
-- Custom logHook
-- configure xmobar looks

-- Pretty with colored background
myLogHook h = (workspaceNamesPP $ def
        { ppCurrent = xmobarColor (colLook White 1) (colLook Blue 0) . wrap " " " "
        , ppVisible = xmobarColor (colLook Blue 1) "" . wrap " " " "
        , ppHidden  = xmobarColor (colLook White 1) "" . wrap " " " "
        , ppHiddenNoWindows = xmobarColor (colLook Black 0) "" . wrap " " " "
        , ppUrgent  = xmobarColor (colLook White 1) "" . wrap "[" "]"
        , ppLayout  = xmobarColor (colLook Blue 1) "" .
        (\x -> case x of
         "Spacing Tall"        -> "[]="
         "Spacing Mirror Tall" -> "[-]"
         "Spacing Full"        -> "[F]"
         _                     -> x
        )
        , ppTitle   = xmobarColor (colLook White 1) "" . shorten 80
        , ppSep     = xmobarColor (colLook Grey 0) "" " | "
        , ppWsSep   = xmobarColor "" "" "" -- Eliminates the gap
        , ppOutput  = hPutStrLn h
        }) >>= dynamicLogWithPP

-- Vanilla config
-- myLogHook h = dynamicLogWithPP xmobarPP
--         { ppOutput = hPutStrLn h
--         , ppTitle = xmobarColor "green" "" . shorten 80
--         }


------------------------------------------------------------------------------------------
-- Custom layoutHook
--
-- Configure layouts
-- Referenced https://github.com/altercation/dotfiles-tilingwm.

myLayoutHook =
        fullscreenFocus $ fullscreenFloat $
        -- NB.lessBorders NB.OnlyScreenFloat $
        windowNavigation $
        boringWindows $
        onWorkspace "1" full $
        toggleLayouts full $
        tabbed ||| tall
    where
        spacing = spacingRaw False (Border 15 15 15 15) True (Border 15 15 15 15) True
        addTopBar = noFrillsDeco shrinkText topBarTheme
        named n = renamed [(XMonad.Layout.Renamed.Replace n)]

        tall = named "tall"
            $ avoidStruts
            -- $ NB.noBorders
            -- $ addTopBar
            -- $ spacing
            $ Tall nmaster delta ratio
            where
            -- The default number of windows in the master pane
            nmaster = 1
            -- Percentage of screen to increment by when resizing panes
            delta   = 1/40
            -- Default proportion of screen occupied by master pane
            ratio   = 1/2

        full = named "full"
            $ avoidStruts
            $ NB.noBorders
            $ Full

        tabbed = named "tabbed"
            $ avoidStruts
            -- $ NB.noBorders
            -- $ addTopBar
            $ addTabs shrinkText myTabTheme
            -- $ spacing
            $ subLayout [] Simplest $ Tall 1 (1/40) (1/2)


myFont = "xft:Hack:size=9"

topBarTheme = def
        { fontName = myFont
        -- , inactiveBorderColor = background
        -- , inactiveColor = background
        -- , inactiveTextColor = background
        -- , activeBorderColor = foreground
        -- , activeColor = foreground
        -- , activeTextColor = foreground
        -- , activeBorderWidth = 3
        -- , decoHeight = 15
        }

myTabTheme = def
    { fontName = "xft:Hack:size=8"
    , inactiveBorderColor = background
    , inactiveColor = background
    , inactiveTextColor = "#cccccc"
    , activeColor = foreground
    , activeTextColor = background
    , activeBorderColor = foreground
    , activeBorderWidth = 3
    , decoHeight = 30
    }

------------------------------------------------------------------------------------------
-- Key Bindings
-- Bar
-- FIXME
toggleStrutsKey :: XConfig Layout -> (KeyMask, KeySym)
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)


------------------------------------------------------------------------------------------
-- Color Definitions
type Hex = String
type ColorCode = (Hex, Hex)
type ColorMap = M.Map Colors ColorCode

data Colors = Black | Grey | Red | Green | Yellow | Blue | Magenta | Cyan | White | BG
	deriving (Ord, Show, Eq)

colLook :: Colors -> Int -> Hex
colLook color n =
	case M.lookup color colors of
		Nothing -> "#000000"
		Just (c1,c2) -> if n == 0
						then c1
						else c2

colors :: ColorMap
colors = M.fromList
	[ (Black 	, (	"#555555",
					"#121212"))
	, (Grey 	, (	"#aaaaaa",
					"#121212"))
	, (Red	 	, (	"#c90c25",
					"#F21835"))
	, (Green 	, (	"#308888",
					"#8abeb7"))
	, (Yellow 	, (	"#54777d",
					"#415D62"))
	, (Blue 	, (	"#81a2be",
					"#81a2be"))
	, (Magenta 	, (	"#6f4484",
					"#915eaa"))
	, (Cyan 	, (	"#2B7694",
					"#47959E"))
	, (White 	, (	"#D6D6D6",
					"#EEEEEE"))
	, (BG	 	, (	"#000000",
					"#444444"))
	]


------------------------------------------------------------------------------------------
-- Fullscreen fix
--
-- See: https://github.com/xmonad/xmonad-contrib/issues/183#issuecomment-307407822
addNETSupported :: Atom -> X ()
addNETSupported x   = withDisplay $ \dpy -> do
    r               <- asks theRoot
    a_NET_SUPPORTED <- getAtom "_NET_SUPPORTED"
    a               <- getAtom "ATOM"
    liftIO $ do
       sup <- (join . maybeToList) <$> getWindowProperty32 dpy a_NET_SUPPORTED r
       when (fromIntegral x `notElem` sup) $
         changeProperty32 dpy r a_NET_SUPPORTED a propModeAppend [fromIntegral x]

addEWMHFullscreen :: X ()
addEWMHFullscreen   = do
    wms <- getAtom "_NET_WM_STATE"
    wfs <- getAtom "_NET_WM_STATE_FULLSCREEN"
    mapM_ addNETSupported [wms, wfs]
