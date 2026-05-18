import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():

    print('🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪')

    use_sim_time = LaunchConfiguration('use_sim_time')
    amcl_config = LaunchConfiguration('amcl_config')
    map_arg = LaunchConfiguration('map')

    # Default configs
    default_amcl = os.path.join(
        get_package_share_directory('fastbot_slam'), 'config', 'amcl_config.yaml')
    default_map = os.path.join(
        get_package_share_directory('fastbot_slam'), 'maps', 'small_apartment.yaml')

    return LaunchDescription([

        DeclareLaunchArgument(
            'use_sim_time',
            default_value='True',
            description='Use simulation time — set False for real robot'
        ),

        DeclareLaunchArgument(
            'amcl_config',
            default_value=default_amcl,
            description='AMCL config yaml. '
                        'Default: amcl_config.yaml (simulation). '
                        'Real robot: amcl_config_real.yaml'
        ),

        DeclareLaunchArgument(
            'map',
            default_value=default_map,
            description='Full path to map yaml. '
                        'Default: small_apartment (baked in). '
                        'Override: map:=/maps/my_map.yaml'
        ),

        Node(
            package='nav2_map_server',
            executable='map_server',
            name='map_server',
            output='screen',
            parameters=[{'use_sim_time': use_sim_time},
                        {'yaml_filename': map_arg}]
        ),

        Node(
            package='nav2_amcl',
            executable='amcl',
            name='amcl',
            output='screen',
            parameters=[amcl_config]
        ),

        Node(
            package='nav2_lifecycle_manager',
            executable='lifecycle_manager',
            name='lifecycle_manager_localization',
            output='screen',
            parameters=[{'use_sim_time': use_sim_time},
                        {'autostart': True},
                        {'node_names': ['map_server', 'amcl']}]
        )
    ])