import { Button } from '@/components/Button';
import { ScreenLayout } from '@/components/ScreenLayout';
import { MonoText, SansText, SerifText } from '@/components/Typography';
import { QUICK_TASKS } from '@/constants';
import { useFrictionStore } from '@/stores';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import * as Haptics from 'expo-haptics';
import React, { useState } from 'react';
import {
    TextInput,
    View
} from 'react-native';

export default function TasksScreen() {
  const { tasks, addTask, completeTask, deleteTask } = useFrictionStore();
  const [newTaskTitle, setNewTaskTitle] = useState('');
  const [showAddTask, setShowAddTask] = useState(false);

  const pendingTasks = tasks.filter((t) => !t.completed);
  const completedTasks = tasks.filter((t) => t.completed);

  const handleAddQuickTask = (quickTask: typeof QUICK_TASKS[0]) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    addTask({
      title: quickTask.title,
      type: 'quick',
      verificationType: quickTask.verificationType,
      verificationPrompt: quickTask.prompt,
    });
  };

  const handleAddCustomTask = () => {
    if (!newTaskTitle.trim()) return;

    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    addTask({
      title: newTaskTitle.trim(),
      type: 'custom',
      verificationType: 'none',
    });
    setNewTaskTitle('');
    setShowAddTask(false);
  };

  const handleCompleteTask = (taskId: string) => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    completeTask(taskId);
  };

  const handleDeleteTask = (taskId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    deleteTask(taskId);
  };

  return (
    <ScreenLayout scrollable>
      {/* Header */}
      <View className="mb-8">
        <MonoText className="text-white/40 text-xs uppercase tracking-[4px]">
          Tasks
        </MonoText>
        <SerifText className="text-white text-3xl mt-1">
          Your Commitments
        </SerifText>
        <SansText className="text-white/50 mt-2 text-sm">
          Complete tasks to unlock distraction apps.
        </SansText>
      </View>

      {/* Pending Tasks */}
      {pendingTasks.length > 0 && (
        <View className="mb-8">
          <MonoText className="text-white/60 text-sm mb-3 uppercase tracking-wider">
            Pending ({pendingTasks.length})
          </MonoText>
          {pendingTasks.map((task) => (
            <View
              key={task.id}
              className="bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.08)] rounded-2xl p-4 mb-3 flex-row items-center justify-between"
            >
              <View className="flex-1 mr-3">
                <SansText className="text-white text-lg">{task.title}</SansText>
                <MonoText className="text-white/40 text-xs mt-1 uppercase">
                  {task.verificationType === 'photo'
                    ? 'Photo required'
                    : task.verificationType === 'motion'
                    ? 'Motion tracked'
                    : 'Self-verify'}
                </MonoText>
              </View>
              <View className="flex-row gap-2">
                <Button 
                   variant="primary" 
                   size="sm" 
                   onPress={() => handleCompleteTask(task.id)}
                   hitSlop={{ top: 15, bottom: 15, left: 10, right: 5 }}
                >
                  <FontAwesome name="check" size={14} color="#000" />
                </Button>
                <Button 
                   variant="ghost" 
                   size="sm" 
                   onPress={() => handleDeleteTask(task.id)}
                   hitSlop={{ top: 15, bottom: 15, left: 5, right: 10 }}
                >
                   <FontAwesome name="trash" size={14} color="#666" />
                </Button>
              </View>
            </View>
          ))}
        </View>
      )}

      {/* Quick Tasks */}
      <View className="mb-8">
        <MonoText className="text-white/60 text-sm mb-3 uppercase tracking-wider">
          Quick Tasks
        </MonoText>
        <View className="flex-row flex-wrap gap-2">
          {QUICK_TASKS.map((task) => (
            <Button
              key={task.id}
              onPress={() => handleAddQuickTask(task)}
              variant="outline"
              size="sm"
            >
              {task.title}
            </Button>
          ))}
        </View>
      </View>

      {/* Add Custom Task */}
      <View className="mb-8">
        {showAddTask ? (
          <View className="bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.08)] rounded-2xl p-4">
            <TextInput
              className="text-white text-lg mb-4 font-[Outfit-Regular]"
              placeholder="What do you commit to?"
              placeholderTextColor="#666"
              value={newTaskTitle}
              onChangeText={setNewTaskTitle}
              autoFocus
              returnKeyType="done"
              onSubmitEditing={handleAddCustomTask}
            />
            <View className="flex-row justify-end gap-2">
              <Button 
                variant="ghost" 
                size="sm" 
                onPress={() => setShowAddTask(false)}
              >
                Cancel
              </Button>
              <Button 
                variant="primary" 
                size="sm" 
                onPress={handleAddCustomTask}
              >
                Add
              </Button>
            </View>
          </View>
        ) : (
          <Button
            variant="outline"
            onPress={() => setShowAddTask(true)}
            className="w-full border-dashed border-white/20 py-4"
            icon={<FontAwesome name="plus" size={16} color="#666" />}
          >
            Add Custom Task
          </Button>
        )}
      </View>

      {/* Completed Tasks */}
      {completedTasks.length > 0 && (
        <View>
          <MonoText className="text-white/60 text-sm mb-3 uppercase tracking-wider">
            Completed ({completedTasks.length})
          </MonoText>
          {completedTasks.slice(0, 5).map((task) => (
            <View
              key={task.id}
              className="bg-white/5 border border-white/5 rounded-2xl p-4 mb-3 opacity-50"
            >
              <View className="flex-row items-center">
                <FontAwesome name="check-circle" size={18} color="#FFA500" />
                <SansText className="text-white/70 text-lg ml-3 line-through">
                  {task.title}
                </SansText>
              </View>
            </View>
          ))}
        </View>
      )}

      {/* Empty State */}
      {pendingTasks.length === 0 && completedTasks.length === 0 && (
        <View className="py-12 items-center">
          <FontAwesome name="list-ul" size={48} color="#333" />
          <SansText className="text-white/40 text-center mt-4">
            No tasks yet.{'\n'}
            Add tasks to create friction before distractions.
          </SansText>
        </View>
      )}
    </ScreenLayout>
  );
}
