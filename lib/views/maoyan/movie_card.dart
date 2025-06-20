import 'package:flutter/material.dart';
import 'package:yifeng_site/models/global_box_office.dart';

class MovieCard extends StatelessWidget {
  final MovieBoxOffice movie;
  final int rank;

  const MovieCard({super.key, required this.movie, required this.rank});

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[300]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
    } else {
      rankColor = Colors.blueGrey[100]!;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: rank <= 3 ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.movieName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '上映年份: ${movie.releaseTime}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (movie.indexItems != null && movie.indexItems!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: movie.indexItems!.map((item) {
                          return Chip(
                            label: Text(
                              '${item.title}: ${item.boxInfo}${item.unitDesc}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[50],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${movie.box}亿',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  '人民币',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}