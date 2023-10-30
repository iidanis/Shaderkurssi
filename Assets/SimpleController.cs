using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class SimpleController : MonoBehaviour
{

        [SerializeField] private Material ProximityMaterial;
        private static int PlayerPosID = Shader.PropertyToID("_PlayerPosition");

        void Update()
        {
            Vector3 movement = Vector3.zero;
            if (Input.GetKey(KeyCode.A))
                movement += Vector3.left;
            if (Input.GetKey(KeyCode.W))
                movement += Vector3.forward;
            if (Input.GetKey(KeyCode.D))
                movement += Vector3.right;

            if (Input.GetKey(KeyCode.S))
                movement += Vector3.back;

            transform.Translate(Time.deltaTime * 5 * movement.normalized, Space.World);

            ProximityMaterial.SetVector(PlayerPosID, transform.position);
        }
}
