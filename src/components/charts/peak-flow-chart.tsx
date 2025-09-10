'use client'

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ReferenceLine } from 'recharts'
import { format, subDays, startOfDay } from 'date-fns'

interface PeakFlowData {
  date: string
  value: number
  personalBest?: number
  zone?: 'green' | 'yellow' | 'red'
}

interface PeakFlowChartProps {
  data: PeakFlowData[]
  personalBest?: number
}

// Generate mock data for demo
const generateMockData = (days: number = 7): PeakFlowData[] => {
  const data: PeakFlowData[] = []
  const personalBest = 450
  
  for (let i = days - 1; i >= 0; i--) {
    const date = startOfDay(subDays(new Date(), i))
    const baseValue = personalBest - Math.random() * 100
    const value = Math.round(baseValue + (Math.random() - 0.5) * 60)
    
    let zone: 'green' | 'yellow' | 'red' = 'green'
    const percentage = (value / personalBest) * 100
    
    if (percentage < 50) zone = 'red'
    else if (percentage < 80) zone = 'yellow'
    
    data.push({
      date: format(date, 'MMM dd'),
      value,
      personalBest,
      zone
    })
  }
  
  return data
}

export function PeakFlowChart({ data, personalBest = 450 }: PeakFlowChartProps) {
  const chartData = data.length > 0 ? data : generateMockData()
  
  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      const percentage = Math.round((data.value / personalBest) * 100)
      
      return (
        <div className="bg-white border border-gray-200 rounded-lg p-3 shadow-lg">
          <p className="font-medium">{label}</p>
          <p className="text-blue-600">
            Peak Flow: <span className="font-bold">{data.value} L/min</span>
          </p>
          <p className="text-gray-600">
            {percentage}% of personal best
          </p>
          <p className={`text-sm font-medium ${
            data.zone === 'green' ? 'text-green-600' : 
            data.zone === 'yellow' ? 'text-yellow-600' : 'text-red-600'
          }`}>
            {data.zone === 'green' ? '🟢 Green Zone' :
             data.zone === 'yellow' ? '🟡 Yellow Zone' : '🔴 Red Zone'}
          </p>
        </div>
      )
    }
    return null
  }

  const formatYAxis = (value: number) => `${value}`

  return (
    <div className="w-full h-64 sm:h-80">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart
          data={chartData}
          margin={{
            top: 20,
            right: 30,
            left: 20,
            bottom: 20,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
          <XAxis 
            dataKey="date" 
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 12 }}
          />
          <YAxis 
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 12 }}
            tickFormatter={formatYAxis}
            domain={['dataMin - 20', 'dataMax + 20']}
          />
          <Tooltip content={<CustomTooltip />} />
          
          {/* Zone reference lines */}
          <ReferenceLine 
            y={personalBest * 0.8} 
            stroke="#f59e0b" 
            strokeDasharray="5 5" 
            label={{ value: "Yellow Zone", position: "top", fontSize: 10 }}
          />
          <ReferenceLine 
            y={personalBest * 0.5} 
            stroke="#ef4444" 
            strokeDasharray="5 5"
            label={{ value: "Red Zone", position: "top", fontSize: 10 }}
          />
          
          <Line
            type="monotone"
            dataKey="value"
            stroke="#3b82f6"
            strokeWidth={3}
            dot={{ fill: '#3b82f6', strokeWidth: 2, r: 4 }}
            activeDot={{ r: 6, stroke: '#3b82f6', strokeWidth: 2 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}