'use client'

import { useState, useEffect } from 'react'

interface OfflineAction {
  id: string
  type: 'LOG_ENTRY' | 'ACTION_PLAN' | 'PROFILE_UPDATE'
  data: any
  timestamp: number
  retryCount: number
}

export function useOfflineSync() {
  const [isOnline, setIsOnline] = useState(true)
  const [pendingActions, setPendingActions] = useState<OfflineAction[]>([])
  const [syncStatus, setSyncStatus] = useState<'idle' | 'syncing' | 'error'>('idle')

  // Monitor online status
  useEffect(() => {
    const handleOnline = () => setIsOnline(true)
    const handleOffline = () => setIsOnline(false)

    // Initial status
    setIsOnline(navigator.onLine)

    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [])

  // Load pending actions from localStorage
  useEffect(() => {
    const stored = localStorage.getItem('offline-actions')
    if (stored) {
      try {
        setPendingActions(JSON.parse(stored))
      } catch (error) {
        console.error('Error loading offline actions:', error)
      }
    }
  }, [])

  // Save pending actions to localStorage
  useEffect(() => {
    localStorage.setItem('offline-actions', JSON.stringify(pendingActions))
  }, [pendingActions])

  // Sync when coming back online
  useEffect(() => {
    if (isOnline && pendingActions.length > 0) {
      syncPendingActions()
    }
  }, [isOnline, pendingActions])

  const addOfflineAction = (action: Omit<OfflineAction, 'id' | 'timestamp' | 'retryCount'>) => {
    const newAction: OfflineAction = {
      ...action,
      id: Math.random().toString(36).substr(2, 9),
      timestamp: Date.now(),
      retryCount: 0
    }

    setPendingActions(prev => [...prev, newAction])

    if (isOnline) {
      // Try to sync immediately if online
      syncAction(newAction)
    }
  }

  const syncAction = async (action: OfflineAction): Promise<boolean> => {
    try {
      // Simulate API call based on action type
      switch (action.type) {
        case 'LOG_ENTRY':
          // await api.createLogEntry(action.data)
          console.log('Syncing log entry:', action.data)
          break
        case 'ACTION_PLAN':
          // await api.updateActionPlan(action.data)
          console.log('Syncing action plan:', action.data)
          break
        case 'PROFILE_UPDATE':
          // await api.updateProfile(action.data)
          console.log('Syncing profile update:', action.data)
          break
      }

      // Remove successful action from pending list
      setPendingActions(prev => prev.filter(a => a.id !== action.id))
      return true
    } catch (error) {
      console.error('Error syncing action:', error)
      
      // Increment retry count
      setPendingActions(prev => 
        prev.map(a => 
          a.id === action.id 
            ? { ...a, retryCount: a.retryCount + 1 }
            : a
        )
      )
      return false
    }
  }

  const syncPendingActions = async () => {
    if (!isOnline || pendingActions.length === 0) return

    setSyncStatus('syncing')
    
    try {
      const syncPromises = pendingActions
        .filter(action => action.retryCount < 3) // Max 3 retries
        .map(action => syncAction(action))

      await Promise.allSettled(syncPromises)
      
      // Clean up actions that have exceeded retry limit
      setPendingActions(prev => 
        prev.filter(action => action.retryCount < 3)
      )

      setSyncStatus('idle')
    } catch (error) {
      setSyncStatus('error')
    }
  }

  const clearPendingActions = () => {
    setPendingActions([])
    localStorage.removeItem('offline-actions')
  }

  return {
    isOnline,
    pendingActions,
    syncStatus,
    addOfflineAction,
    syncPendingActions,
    clearPendingActions
  }
}