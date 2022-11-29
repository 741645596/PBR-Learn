using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(WaterColor))]
public class WaterColorEditor : Editor
{
    // Start is called before the first frame update

    private WaterColor watercolor;

    void OnEnable() 
    {
        watercolor = target as WaterColor;
    }
    public override void OnInspectorGUI()
    {
        base.DrawDefaultInspector();

        if (GUILayout.Button("保存紋理"))
        {
            Debug.LogError(watercolor.RampTexture);
            string path = EditorUtility.SaveFilePanel("保存紋理","","WaterColorRampMap","png");
            System.IO.File.WriteAllBytes(path,watercolor.RampTexture.EncodeToPNG());
            AssetDatabase.Refresh();
        }
        
    }
}
