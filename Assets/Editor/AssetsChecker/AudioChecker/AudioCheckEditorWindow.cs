
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using EditerUtils;
using UnityEditor.IMGUI.Controls;


public class AudioCheckEditorWindow : AssetCheckEditorWindowBase<AudioAssetInfo>
{
    public const string Title = "音频资源";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "1、移动平台建议使用单声道（勾选Force To Mono），建议使用原声音量（取消勾选Normalize）\n" +
            "2、规定：音效设置为DecompressOnLoad，背景音乐设置为Streaming；压缩格式为Vorbis。（暂定播放时长小于5s表示音效文件）\n" +
            "3、Quality建议值为88\n" +
            "4、移动平台建议采样率为22050";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowFixAll()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        ShowProblemToggle();

        GUI.color = Color.green;
        if (GUILayout.Button("全部修复", GUILayout.Width(100)))
        {
            AudioCheckLogic.FixAll(_showInfos, (isCancel)=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;

        if (GUILayout.Button("设置采样率", GUILayout.Width(100)))
        {
            _ClickSampleRateAction();
        }

        EditorGUILayout.EndHorizontal();
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<AudioAssetInfo>> finishCB)
    {
        AudioCheckLogic.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(AudioAssetInfo info, Rect rect, bool isError)
    {
        // 修复按钮
        if (isError)
        {
            GUILogicHelper.ShowFixBt(rect, () =>
            {
                info.Fix();

                Reload();
            });
        }
    }

    protected override void OnShowTopInfo()
    {
        // 显示规则信息
        _ShowRuleDes();

        // 显示复选框和全部修复按钮
        _ShowFixAll();
    }

    protected override float OnGetListViewPosY()
    {
        return 120.0f;
    }

    protected override List<AudioAssetInfo> OnGetShowInfos()
    {
        var showInfos = _isFilter ? AudioCheckLogic.GetErrorAssetInfos(_assetsInfos) : _assetsInfos;
        showInfos.Sort((a, b) =>
        {
            return b.audioLength > a.audioLength ? 1 : -1;
        });
        return showInfos;
    }

    private void _ClickSampleRateAction()
    {
        var pops = new List<string>()
        {
            "默认",
            "22050",
        };
        AssetsCheckUILogic.ShowPopMenu(pops, (index) =>
        {
            if (index == 0)
            {
                _SetDefaultSampleRate();
            }
            else 
            {
                _SetSampleRate(AudioAssetInfo.Sample_Rate);
            }
        });
    }

    private void _SetSampleRate(uint rate)
    {
        FixHelper.FixStep<AudioAssetInfo>(_showInfos, (info) =>
        {
            info.SetSampleRate(rate);
        },
        (isCancel) =>
        {
            Reload();
        });
    }

    private void _SetDefaultSampleRate()
    {
        FixHelper.FixStep<AudioAssetInfo>(_showInfos, (info) =>
        {
            info.RevertSampleRate();
        },
        (isCancel) =>
        {
            Reload();
        });
    }
}
